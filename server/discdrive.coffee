'use strict'
import Discord from 'discord.js-12'
import { FailDrive } from './imports/drive.coffee'


class DiscDrive
  constructor: (token, @guildId) ->
    @disc = "bla" 
    @drive = @guildId
  
# Intialize APIs and load rootFolder
if Meteor.isAppTest
  share.drive = new FailDrive
  return
Promise.await do ->
  try
    return unless share.DO_BATCH_PROCESSING
    console.log "~~~driving a disc~~~"

    # this is the discord server ID you want to run galackbot and integrate galackboard with.
    # ensure guild ID is set in Meteor settings: settings.public.discordServerId
    guildId = Meteor.settings.public?.discordServerId
    if !guildId?
      console.log "No Discord Server ID found in Meteor public settings: settings.public.discordServerId"
      console.log "Discord integration disabled."

      share.discdrive = {"bad":"NO GUILD ID: [" + guildId + "]"}
      return

    # this is galackbot's token:
    #  create an app in https://discord.com/developers/applications
    #  add a bot to the app, copy the bot token and set env DISCORD_BOT_TOKEN
    #  add the bot to the server with Admin permissions:
    #    OAuth2 -> URL Generator -> Scopes:bot -> Bot Permissions:Administrator

    # ensure token is set at env.DISCORD_BOT_TOKEN
    token = process.env.DISCORD_BOT_TOKEN
    if !token?
      console.log "No Discord Bot Token found in environment variables: process.env.DISCORD_BOT_TOKEN"
      console.log "Discord integration disabled."

      share.discdrive = {"bad":"NO TOKEN: [" + token + "]"}
      return

    console.log "~~~we can drive a disc with token, guildId: " + token + ", " + guildId + "~~~"
    share.discdrive = new DiscDrive token, guildId
  catch error
    console.log "Error driving a disc:", error
    share.discdrive = new FailDrive
