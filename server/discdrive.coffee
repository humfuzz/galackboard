'use strict'

import { Drive, FailDrive } from './imports/drive.coffee'
import { decrypt } from './imports/crypt.coffee'
import { google } from 'googleapis'

# helper functions to perform Google Drive operations

# Credentials
KEY = Meteor.settings.key or try
  Assets.getBinary 'drive-key.pem.crypt'
catch error
  undefined
if KEY? and Meteor.settings.password?
  # Decrypt the JWT authentication key synchronously at startup
  KEY = decrypt KEY, Meteor.settings.password
EMAIL = Meteor.settings.email or '571639156428@developer.gserviceaccount.com'
SCOPES = ['https://www.googleapis.com/auth/drive']

class DiscDrive
  constructor: (@drive) ->
    @rootFolder = "bla" 
    @ringhuntersFolder = "hey"
  
  createPuzzle: (name) ->
    return {
      id: "folder.id"
      spreadId: "spreadsheet.id"
      docId: "doc.id"
    }

  findPuzzle: (name) ->
    resp = apiThrottle @drive.children, 'list',
      folderId: @rootFolder
      q: "title=#{quote name} and mimeType=#{quote GDRIVE_FOLDER_MIME_TYPE}"
      maxResults: 1
    folder = resp.items[0]
    return null unless folder?
    # TODO: batch these requests together.
    # look for spreadsheet
    spread = apiThrottle @drive.children, 'list',
      folderId: folder.id
      q: "title=#{quote WORKSHEET_NAME name}"
      maxResults: 1
    doc = apiThrottle @drive.children, 'list',
      folderId: folder.id
      q: "title=#{quote DOC_NAME name}"
      maxResults: 1
    return {
      id: folder.id
      spreadId: spread.items[0]?.id
      docId: doc.items[0]?.id
    }

  listPuzzles: ->
    results = []
    resp = {}
    loop
      resp = apiThrottle @drive.children, 'list',
        folderId: @rootFolder
        q: "mimeType=#{quote GDRIVE_FOLDER_MIME_TYPE}"
        maxResults: MAX_RESULTS
        pageToken: resp.nextPageToken
      results.push resp.items...
      break unless resp.nextPageToken?
    results

  renamePuzzle: (name, id, spreadId, docId) ->
    apiThrottle @drive.files, 'patch',
      fileId: id
      resource:
        title: name
    if spreadId?
      apiThrottle @drive.files, 'patch',
        fileId: spreadId
        resource:
          title: WORKSHEET_NAME name
    if docId?
      apiThrottle @drive.files, 'patch',
        fileId: docId
        resource:
          title: DOC_NAME name
    'ok'

  deletePuzzle: (id) -> rmrfFolder @drive, id

  shareFolder: (email) -> ensureNamedPermissions @drive, @rootFolder, email

  # purge `rootFolder` and everything in it
  purge: -> rmrfFolder @drive, rootFolder

# Intialize APIs and load rootFolder
if Meteor.isAppTest
  share.drive = new FailDrive
  return
Promise.await do ->
  try
    auth = null
    if /^-----BEGIN RSA PRIVATE KEY-----/.test(KEY)
      auth = new google.auth.JWT(EMAIL, null, KEY, SCOPES)
      await auth.authorize()
    else
      auth = await google.auth.getClient scopes: SCOPES
    # record the API and auth info
    api = google.drive {version: 'v2', auth}
    share.discdrive = new DiscDrive
    console.log "Google Drive authorized and activated"
  catch error
    console.warn "Error trying to retrieve drive API:", error
    console.warn "Google Drive integration disabled."
    share.discdrive = new FailDrive
