'use strict'
import Discord from 'discord.js-12'
import { FailDrive } from './imports/drive.coffee'


class DiscDrive
  constructor: (token, guildId) ->
    client = new (Discord.Client)
    client.login token

    client.on 'ready', () -> # bind stuff
      guild = await client.guilds.fetch(guildId)

      console.log "Discord bot connected."
      # debug "Discord bot connected."

    @client = client
    @guild = "hey"
  
# Intialize APIs and load rootFolder
if Meteor.isAppTest
  share.drive = new FailDrive
  return
Promise.await do ->
  try

    # this is the discord server ID you want to run galackbot and integrate galackboard with.
    # ensure guild ID is set in Meteor settings: settings.public.discordServerId
    guildId = Meteor.settings.public?.discordServerId
    if !guildId?
      console.warn "No Discord Server ID found in Meteor public settings: settings.public.discordServerId"
      console.warn "Discord integration disabled."

      share.discord = new NoDiscordBot
      return

    # this is galackbot's token:
    #  create an app in https://discord.com/developers/applications
    #  add a bot to the app, copy the bot token and set env DISCORD_BOT_TOKEN
    #  add the bot to the server with Admin permissions:
    #    OAuth2 -> URL Generator -> Scopes:bot -> Bot Permissions:Administrator

    # ensure token is set at env.DISCORD_BOT_TOKEN
    token = process.env.DISCORD_BOT_TOKEN
    if !token?
      console.warn "No Discord Bot Token found in environment variables: process.env.DISCORD_BOT_TOKEN"
      console.warn "Discord integration disabled."

      share.discord = new NoDiscordBot
      return

    console.log "Initializing Discord bot:", token, guildId


    share.discdrive = new DiscDrive token, guildId
  catch error
    console.warn "Error driving a disc:", error
    share.discdrive = new FailDrive
