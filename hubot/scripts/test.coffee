# Description:
#   Information for Tracking issue completion
#
# Configuration:
#   CHAT_WEBHOOK_URL The webhook to post to. Currently only supports 1.
#   USER_MAP_JSON The full path to the location of the user map json. Must be present.
#   GITHUB SECRET A shared secret between github and this application
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
