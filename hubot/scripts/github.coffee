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

  robot.router.post '/testy', (req, res) ->
    robot.logger.info "test"

    res.send 'OK'

  robot.router.post '/env', (req, res) ->
    robot.logger.info "Webhook url ", process.env.CHAT_WEBHOOK_URL
    robot.logger.info "Github ", process.env.GITHUB_SECRET
    robot.logger.info "User map ", userMap

    res.send 'OK'

  robot.router.post '/github', (req, res) ->
    token = req.headers['x-hub-signature-256']

    correctSignature = isCorrectSignature(token, req.body)

    if correctSignature
      event = req.headers['x-github-event']
      robot.logger.info event

      message = "";
      threadId = "";

      if event == 'pull_request'
        message = pullRequestMessage(req.body)
        threadId = 'pr-' + req.body.pull_request.id
      else if event == 'pull_request_review'
        message = pullRequestReview(req.body)
        threadId = 'pr-' + req.body.pull_request.id
      else if event == 'release'
        message = releaseMessage(req.body)
        threadId = 'release'
      else if event == 'push' and "refs/heads/" + req.body.repository.default_branch == req.body.ref
        message = pushMessage(req.body)
        threadId = "push"

      robot.logger.info message
      chatUrl = process.env.CHAT_WEBHOOK_URL + '&threadKey=' + threadId
      robot.http(chatUrl)
        .header('Content-Type', 'application/json')
        .post(message) (err, resp, body) ->
          if err
            res.send(400).send 'Error posting to chat'
          else
            res.send 'OK'
    else
      robot.logger.info 'Bad signature ', token
      res.status(401).send 'Ye shall not pass'

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
