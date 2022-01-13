# prefix string for solved channels.
#  use '✓-' for a clean look or use an emoji like 🛫
solvePrefix = '✓-'

# remove illegal characters and then keep under 90chars 
#   max channel name is 100, but we save some for prefixes
safeName = (name) ->
  return name.replace(/[!@#$%^&*()+=|'"?.><,~`\[\]\\\/]/g, '').slice(0,90)

    
debug = (str, channel) ->
  channel.send(new Date().toISOString())
  channel.send(str)

export class DiscordBot
  constructor: (@guild, @client, @debugChannel) ->
    @debug("Discord bot connected.")

  debug: (str) ->
    debug(str, @debugChannel)

  # create discord channel category with given name
  createCategory: (name) ->
    @debug("createCategory " + name)

    try 
      channel = await @guild.channels.create(safeName(name), {
        type: 'category'
      })
      return channel.id
    catch e
      @debug("ERROR " + e)

      throw e

  # create discord channel with given name
  # if given categoryId, then put channel under category
  createChannel: (name, categoryId) ->

    console.log 'creating discord channel with name ' + name
    @debug("createChannel " + name + ", " + categoryId + ", safeName: " + safeName)

    channel = await @guild.channels.create(safeName(name))

    # add to round category
    if categoryId?
      channel.setParent(categoryId)

    return channel.id
  
  # rename existing channel with id to name
  renameChannel: (id, name) ->
    channel = await @client.channels.fetch(id)

    if channel.name.startsWith(solvePrefix)
      channel.setName(solvePrefix + safeName(name))
    else 
      channel.setName(safeName(name))
    return channel.id

  # add solvePrefix in front of channel name if solved
  markChannelSolved: (id, answer) ->
    channel = await @client.channels.fetch(id)
    if !channel.name.startsWith(solvePrefix)
      channel.setName(solvePrefix + channel.name)
    channel.send("Puzzle solved! Answer: `" + answer + "`")
      .then (message) ->
        message.react('🎉')

  # remove solvePrefix in front of channel name if unsolved
  markChannelUnsolved: (id) ->
    channel = await @client.channels.fetch(id)
    if channel.name.startsWith(solvePrefix)
      channel.setName(channel.name.slice(solvePrefix.length))
    channel.send("Puzzle has been marked unsolved.")