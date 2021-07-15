# Description:
#   Information for Tracking issue completion
#
# Configuration:
#   CHAT_WEBHOOK_URL The webhook to post to. Currently only supports 1.
#   USER_MAP_JSON The full path to the location of the user map json. Must be present.
#   GITHUB SECRET A shared secret between github and this application
#
#
# Author:
#   mcanoy
crypto = require 'crypto'
userMap = require(process.env.USER_MAP_JSON)

module.exports = (robot) ->

  robot.router.post '/github', (req, res) ->
    token = req.headers['x-hub-signature-256']

    correctSignature = isCorrectSignature(token, req.body)

    if correctSignature
      event = req.headers['x-github-event']
      robot.logger.info event

      getThreadKey(robot, req.body, event).then (threadKey) ->
        return threadKey
      .then ( threadKey ) ->
        getMessage(req.body, event).then (message) ->
          chatData = { message: message, threadKey: threadKey }
          return chatData
      .then ( chatData ) ->
         chatUrl = process.env.CHAT_WEBHOOK_URL + '&threadKey=' + chatData.threadKey
         robot.http(chatUrl).header('Content-Type', 'application/json')
           .post(chatData.message) (err, resp, body) ->
             if err
               robot.logger.error "error", err
               res.send(400).send 'Error posting to chat'
             else
               res.send 'OK'
       .catch (error) ->
         robot.logger.error error
         res.status(400).send error
       .then () ->
         robot.logger.info "fin"
    else
      robot.logger.info 'Bad signature ', token
      res.status(401).send 'Ye shall not pass'

getThreadKey = (robot, body, event) ->
  return new Promise (resolve, reject) ->
    if event == 'pull_request' || event == 'pull_request_review'
      resolve 'pr-' + body.pull_request.id
    else if event == 'release'
      resolve 'release'
    else if event == 'push' and "refs/heads/" + body.repository.default_branch == body.ref
      re = /(?<=Merge pull request #)(\w+)/i
      pr = body.head_commit.message.match(re)
      if pr?
        prNumber = pr[0]
        repo = body.repository.full_name
        prUrl = "https://api.github.com/repos/#{repo}/pulls/#{prNumber}"
        robot.http(prUrl).header('Content-Type', 'application/json').get() (err, resp, body2) ->
          if err
            reject err
          else
            data = JSON.parse(body2)
            resolve 'pr-' + data.id
    else
      reject 'no thread key found'

getMessage = (body, event) -> 
  return new Promise (resolve, reject) ->
    if event == 'pull_request'
      resolve pullRequestMessage(body)
    else if event == 'pull_request_review'
      resolve pullRequestReview(body)
    else if event == 'release'
      resolve releaseMessage(body)
    else if event == 'push' and "refs/heads/" + body.repository.default_branch == body.ref
      resolve pushMessage(body)
    else
      reject 'no message found' 

githubPush = (robot, body) ->
  return new Promise (resolve, reject) ->
    
    re = /(?<=Merge pull request #)(\w+)/i
    pr = body.head_commit.message.match(re)
    if pr?
      prNumber = pr[0]
      repo = body.repository.full_name
      prUrl = "https://api.github.com/repos/#{repo}/pulls/#{prNumber}"
      robot.http(prUrl).header('Content-Type', 'application/json').get() (err, resp, body2) ->
        err ? reject err  : resolve body2  
    else 
      reject err   
      


pushMessage = (body) ->
  re = /(?<=Merge pull request #)(\w+)/i
  pr = body.head_commit.message.match(re)
  if pr?
    prNumber = pr[0]
    repo = body.repository.full_name
    message = "*PR-#{prNumber}* was merged into `#{repo}`"

  return JSON.stringify({ "text" : message })

releaseMessage = (body) ->
  releaseNotes = body.release.body
  action = body.action
  release = body.release.tag_name
  repo = body.repository.full_name
  user = getUserName(body.sender.login)

  message = "Release `#{release}` was #{action} for repo `#{repo}` by #{user}\r\n\r\n```#{releaseNotes}```"

  return JSON.stringify({ "text" : message })

pullRequestReview = (body) ->
  prNumber = body.pull_request.number
  user = getUserName(body.review.user.login)
  state = if body.review.state == 'changes_requested' then 'requested changes to ' else body.review.state
  message = "#{user} #{state} *PR-#{prNumber}*"

  return JSON.stringify({ "text" : message })

pullRequestMessage = (body) ->
  prUrl = if body.action == 'opened' then "<#{body.pull_request.html_url}|#{body.pull_request.html_url}>" else ''
  number = body.pull_request.number
  action = body.action
  user = getUserName(body.pull_request.user.login)
  repo = body.repository.full_name
  title = body.pull_request.title
  message = "*PR-#{number}* `#{title}` was #{action} by #{user} in the repo `#{repo}` #{prUrl}"

  if action == 'review_requested'
    reviewers = "";
    for rev in body.pull_request.requested_reviewers
      reviewers = reviewers + getUserName(rev.login) + ' '
    message = "#{reviewers}-  Your review requested for *PR-#{number}*"
  else if action == 'review_request_removed'
    message = "A reviewer was removed from *PR-#{number}*"

  return JSON.stringify({ "text" : message })

getUserName = (user) ->
  return if userMap[user]? then "<users/" + userMap[user] + ">" else user

# https://gist.github.com/ryuichiueda/f7ae2b58c3f6b788dd87
isCorrectSignature = (signature, body) ->
  pairs = signature.split '='
  digest_method = pairs[0]
  hmac = crypto.createHmac digest_method, process.env.GITHUB_SECRET
  hmac.update JSON.stringify(body), 'utf-8'
  hashed_data = hmac.digest 'hex'
  generated_signature = [digest_method, hashed_data].join '='
  return signature is generated_signature
