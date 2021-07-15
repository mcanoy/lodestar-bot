# Description:
#   Information for the LodeStar application
#
# Configuration:
#   WEBHOOK_TOKEN Matching the Gitlab token
#   HANGOUTS_SPACE The space to push messages to when not hearing or responding
#   GOOGLE_APPLICATION_CREDENTIALS The google service account json
#
# Commands:
#   hubot engagments - A count of engagements 
#   hubot engagement <customer> <engagement> - Get information on an engagement
#   hubot card <card> - Test out card json without pushing it to the server
#
# Author:
#   mcanoy
## 
  module.exports = (robot) ->
## 
##   class TokenService
##     constructor: (robot) ->
##       @clientId = process.env.CLIENT_ID
##       @clientSecret = process.env.CLIENT_SECRET
## 
##     getToken: ->
##       return robot.brain.get 'accessToken'
##     renewToken: ->
##       robot.brain.set 'accessToken', null
##       
##       robot.http("#{process.env.SSO_URL}")
##         .header('Content-Type', 'application/x-www-form-urlencoded')
##         .post("grant_type=client_credentials&client_id=#{@clientId}&client_secret=#{@clientSecret}") (err, res, body) ->
##           toke = JSON.parse(body)
##           robot.logger.info "refreshed token"
##           robot.brain.set 'accessToken', toke.access_token
## 
##   robot.token = new TokenService robot
##   robot.token.renewToken()
##   setInterval () ->
##     robot.token.renewToken()
##   , 290000
## 
##   robot.respond /engagements/i, (res) ->
##     token = robot.token.getToken()
##     residencyCount = 0
##     if token?
##       robot.logger.debug "token-->", token
##       robot.http("#{process.env.BACKEND_URL}/engagements").header('Content-Type', 'application/json').header('Authorization', "Bearer #{token}")
##         .get() (err, response, body) ->
##           if err?
##             robot.logger.error "error", err
##             res.reply "error. no cha cha cha"
##           else if response.statusCode isnt 200
##             robot.logger.warning "bad response", response.statusCode
##             res.reply "cha cha cha. status code #{response.statusCode}. Try again?"
##           else
##             engage = JSON.parse(body)
##             robot.logger.info 'engage', engage.length
##             residencyCount = engage.length
##             res.reply "There are #{residencyCount} engagements"
##     else 
##       res.reply "cha cha cha. no token. what?"
## 
##   robot.respond /engagement (.*) (.*)/i, (res) ->  
##     customer = res.match[1]
##     engagement = res.match[2]
##     token = robot.token.getToken()
##     robot.http("#{process.env.BACKEND_URL}/engagements/customers/#{customer}/projects/#{engagement}")
##       .header('Content-Type', 'application/json').header('Authorization', "Bearer #{token}")
##       .get() (err, response, body) ->
##         if err?
##           robot.logger.error "error", err
##           res.reply "error. no cha cha cha"
##         else if response.statusCode isnt 200
##           robot.logger.warning "bad response", response.statusCode
##           res.reply "cha cha cha. status code #{response.statusCode}. Try again?"
##         else
##           robot.logger.info "body", body
##           engage = JSON.parse(body)
##           robot.logger.info 'engage', engage
## 
##           startDate = engage.start_date.replace /(....)(..)/, "$1-$2-" 
##           endDate = engage.end_date.replace /(....)(..)/, "$1-$2-"
## 
##           res.reply '', JSON.stringify({"header": {"title": "#{engage.project_name}","subtitle": "#{engage.customer_name}","imageUrl": "https://www.gstatic.com/images/icons/material/system/2x/sports_kabaddi_googblue_48dp.png"},
##           "sections": [
##             {"widgets": [{"keyValue": {"topLabel": "Start Date","content": "#{startDate}"}},{"keyValue": {"topLabel": "End Date","content": "#{endDate}"}}]},
##             {"widgets": [{"keyValue": {"topLabel": "Engagement Lead","content": "#{engage.engagement_lead_name}"}},{"keyValue": {"topLabel": "Tech Lead","content": "#{engage.technical_lead_name}"}},{"keyValue": {"topLabel": "Customer Contact","content": "#{engage.customer_contact_name}"}}]},
##             {"widgets": [{"keyValue": {"topLabel": "Cluster","content": "#{engage.ocp_cloud_provider_name} (#{engage.ocp_cloud_provider_region}) #{engage.ocp_version}"}},{"keyValue": {"topLabel": "URL","content": "http://#{engage.ocp_sub_domain}.labs.com"}},{"image": {"imageUrl": "https://raster.shields.io/static/v1?label=LodeStar+Status&message=Cluster+Requested&color=blue&style=for-the-badge&logo=red-hat"}}]}
##             ]})
## 
##   robot.router.post '/hubot/webhooks', (req, res) ->
##     token = req.headers['x-gitlab-token']
##     
##     if token isnt process.env.WEBHOOK_TOKEN
##       throw new Error('Secret did not match')
## 
##     payload = req.body
##     title = payload.project.path_with_namespace.replace /(.*)\/(.*)\/(.*)\/(.*)/, "$3"
##     subtitle = payload.project.path_with_namespace.replace /(.*)\/(.*)\/(.*)\/(.*)/, "$2"
##     author = payload.commits[0].author.email
##     icon = "https://www.gstatic.com/images/icons/material/system/2x/code_googblue_48dp.png"
## 
##     robot.messageRoom process.env.HANGOUTS_SPACE, '', JSON.stringify({"header": {"title": "#{title}","subtitle": "#{subtitle}","imageUrl": "#{icon}"},   "sections": [{"widgets": [{"keyValue": {"topLabel": "Last Commit","content": "#{author}"}},{"buttons": [{ "textButton": { "text": "GO TO REPO", "onClick": {"openLink": { "url": "#{payload.repository.homepage}"}}}}]}]}]})
##         
##     res.send 'OK'
##   
##   robot.respond /card (.*)/i, (res) ->
## 
##     card = res.match[1]
##     robot.logger.info 'card', card
##     res.reply '', card
##   
