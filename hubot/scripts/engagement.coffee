module.exports = (robot) ->

  robot.router.post '/hubot/webhooks/:namespace', (req, res) ->
    ns = req.params.namespace
    token = req.headers['x-gitlab-token']
    

    if token isnt process.env.WEBHOOK_TOKEN
      throw new Error('Secret did not match')

    payload = req.body
    title = payload.project.path_with_namespace.replace /(.*)\/(.*)\/(.*)\/(.*)/, "$3 - $2"
    subtitle = payload.commits[0].author.email
    icon = "https://www.gstatic.com/images/icons/material/system/2x/code_googblue_48dp.png"

    robot.messageRoom process.env.HANGOUTS_SPACE, '', JSON.stringify({"header": {"title": "#{title}","subtitle": "#{subtitle}","imageUrl": "#{icon}"},   "sections": [{"widgets": [{"buttons": [{ "textButton": { "text": "GO TO REPO", "onClick": {"openLink": { "url": "#{payload.repository.homepage}"}}}}]}]}]})
        
    res.send 'OK'

  robot.respond /engagements/i, (res) ->
    residencyCount = 0
    robot.http('http://omp-git-api:8080/api/v1/engagements')
      .get() (err, response, body) ->
        engage = JSON.parse(body)
        robot.logger.info 'engage', engage.length
        residencyCount = engage.length
        res.reply "There are #{residencyCount} engagements"

  robot.respond /engagement (.*) (.*)/i, (res) ->  
    customer = res.match[1]
    engagement = res.match[2]
    robot.http("http://omp-git-api:8080/api/v1/engagements/customer/#{customer}/#{engagement}")
      .get() (err, response, body) ->
        engage = JSON.parse(body)
        startDate = engage.start_date.replace /(....)(..)/, "$1-$2-" 
        endDate = engage.end_date.replace /(....)(..)/, "$1-$2-"
        robot.logger.info 'engage', engage

        robot.logger.info 'card', 

        res.reply '', JSON.stringify({"header": {"title": "#{engage.project_name}","subtitle": "#{engage.customer_name}","imageUrl": "https://www.gstatic.com/images/icons/material/system/2x/sports_kabaddi_googblue_48dp.png"},
        "sections": [
          {"widgets": [{"keyValue": {"topLabel": "Start Date","content": "#{startDate}"}},{"keyValue": {"topLabel": "End Date","content": "#{endDate}"}}]},
          {"widgets": [{"keyValue": {"topLabel": "Engagement Lead","content": "#{engage.engagement_lead_name}"}},{"keyValue": {"topLabel": "Tech Lead","content": "#{engage.technical_lead_name}"}},{"keyValue": {"topLabel": "Customer Contact","content": "#{engage.customer_contact_name}"}}]},
          {"widgets": [{"keyValue": {"topLabel": "Cluster","content": "#{engage.ocp_cloud_provider_name} (#{engage.ocp_cloud_provider_region}) #{engage.ocp_version}"}},{"keyValue": {"topLabel": "URL","content": "http://#{engage.ocp_sub_domain}.labs.com"}},{"image": {"imageUrl": "https://raster.shields.io/static/v1?label=LodeStar+Status&message=Cluster+Requested&color=blue&style=for-the-badge&logo=red-hat"}}]}
          ]})
  
  robot.respond /card (.*)/i, (res) ->
    card = res.match[1]
    robot.logger.info 'card', card
    res.reply '', card
