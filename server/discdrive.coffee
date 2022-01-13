'use strict'

import { FailDrive } from './imports/drive.coffee'


class DiscDrive
  constructor: (@drive) ->
    @disc = "bla" 
    @drive = "hey"
  
# Intialize APIs and load rootFolder
if Meteor.isAppTest
  share.drive = new FailDrive
  return
Promise.await do ->
  try
    share.discdrive = new DiscDrive
  catch error
    console.warn "Error driving a disc:", error
    share.discdrive = new FailDrive
