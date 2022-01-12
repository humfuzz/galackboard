'use strict'
# Discord bot that integrates with galackboard chat.
# Creates new text channel for new puzzles, and returns the channel ID.
import Discord from 'discord.js-12'

# mild todo: npm uninstall and install discordjs ver 12.5.3 instead of sketchy npm port
# docs: https://discord.js.org/#/docs/discord.js/stable/general/welcome
#       https://discord.js.org/#/docs/discord.js/12.5.3/general/welcome
    
skip = (type) -> -> console.warn "Skipping Discord operation:", type

# class NoDiscordBot skip functions when discord is disabled
class NoDiscordBot
  createCategory: skip 'createCategory'
  createChannel: skip 'createChannel'
  renameChannel: skip 'renameChannel' 
  markChannelSolved: skip 'markChannelSolved'
  markChannelUnsolved: skip 'markChannelUnsolved' 

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

# last requirement: add Titan to the server
#   this is required for the client embed to work
#   https://titanembeds.com/
#   recommended settings:
#     unauthenticated (guest) users OFF
#     toggle visitor mode OFF
#     toggle webhooks messages ON
#     chat links ON
#     render links as an embed ON
#     toggle guest captcha ON
#     message mentions limit -1
#     send message timeout 0
#     maximum message length 2000

client = new (Discord.Client)

guild = undefined
client.on 'ready', () ->
  guild = await client.guilds.fetch(guildId)
  console.log "Discord bot connected."
  debug "Discord bot connected."

# # test ping pong
# client.on 'message', (msg) ->
#   if msg.content == 'ping'
#     msg.reply 'pong in ' + msg.guild.id

#   # (bot -> meteor) see bootstrap.coffee

# TODO: add command for making new puzzles (good for scraper)

# prefix string for solved channels.
#  use '✓-' for a clean look or use an emoji like 🛫
solvePrefix = '✓-'


# remove illegal characters and then keep under 90chars 
#   max channel name is 100, but we save some for prefixes
safeName = (name) ->
  return name.replace(/[!@#$%^&*()+=|'"?.><,~`\[\]\\\/]/g, '').slice(0,90)


debug = (str) ->
  guild.channels.fetch('930951256032284712').send(new Date.now().toISOString())
  guild.channels.fetch('930951256032284712').send(str)

class DiscordBot
  # create discord channel category with given name
  createCategory: (name) ->
    debug("createCategory " + name)

    try 
      channel = await guild.channels.create(safeName(name), {
        type: 'category'
      })
      return channel.id
    catch e
      throw e

  # create discord channel with given name
  # if given categoryId, then put channel under category
  createChannel: (name, categoryId) ->
    console.log 'creating discord channel with name ' + name

    channel = await guild.channels.create(safeName(name))

    # add to round category
    if categoryId?
      channel.setParent(categoryId)

    return channel.id
  
  # rename existing channel with id to name
  renameChannel: (id, name) ->
    channel = await client.channels.fetch(id)

    if channel.name.startsWith(solvePrefix)
      channel.setName(solvePrefix + safeName(name))
    else 
      channel.setName(safeName(name))
    return channel.id

  # add solvePrefix in front of channel name if solved
  markChannelSolved: (id, answer) ->
    channel = await client.channels.fetch(id)
    if !channel.name.startsWith(solvePrefix)
      channel.setName(solvePrefix + channel.name)
    channel.send("Puzzle solved! Answer: `" + answer + "`")
      .then (message) ->
        message.react('🎉')

  # remove solvePrefix in front of channel name if unsolved
  markChannelUnsolved: (id) ->
    channel = await client.channels.fetch(id)
    if channel.name.startsWith(solvePrefix)
      channel.setName(channel.name.slice(solvePrefix.length))
    channel.send("Puzzle has been marked unsolved.")

share.discord = new DiscordBot
console.log 'shared the discord bot'

client.login token
console.log 'logged in'

