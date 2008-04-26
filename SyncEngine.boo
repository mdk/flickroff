/* This file is a part of Flickroff
 *
 * Copyright (C) 2008:
 *
 * Authors:
 *	Michael Dominic K. <mdk@mdk.am>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *  
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details. 
 *
 * You should have received a copy of the GNU General Public License 
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

namespace Flickroff

import System
import System.Threading
import System.Collections
import FlickrNet

static class SyncEngine ():

  enum SyncStatus:
    Stopped
    InProgress
    Aborting
    AbortingOnError

  _mainThread as Thread
  _locker as object
  _photoSetQueue as Queue
  _itemsQueue as Queue
  _itemsList as List
  _workerException as Exception
  _status as SyncStatus

  event Success as EventHandler
  event Error as ErrorHandler
  event Finished as EventHandler
  
  callable ErrorHandler (caller as object, exception as Exception)

  def Init ():
    _locker = Object ()
    _status = SyncStatus.Stopped

  def StartSync ():
    _mainThread = Thread (SyncThreadStart)
    _status = SyncStatus.InProgress
    _mainThread.Start ()

  def Abort ():
    lock _locker:
      _status = SyncStatus.Aborting if _status == SyncStatus.InProgress

  private def ProcessPhotosetQueue ():
    threads = []
    try:
      Messenger.DefineProgressRange (_photoSetQueue.Count + 1)
      Messenger.PushMessage ("Downloading {0} sets...", _photoSetQueue.Count + 1)

      # Start the photoset worker threads
      for i in range (0, 3):
        threads.Add (NewPhotoSetWorker ())

      # Photos not in set
      for p in FlickrStore.GetPhotosNotInSet ():
        if not Database.HasPhoto (p.PhotoId, '-1'):
          item = DownloadItem (p, null, Config.PhotosDirectory)
        
          lock _locker:
            _itemsList.Add (item)

      Messenger.Progress ()
    except:
      # FIXME Wrap exception here
      lock _locker:
        _status = SyncStatus.AbortingOnError
      raise
    ensure:
      # Wait for all the worker threads to finish
      WaitForThreadListToJoin (threads)

    lock _locker:
      raise _workerException if _workerException

  private def FillPhotosetQueue ():
    # FIXME Wrap exception here
    Messenger.Reset ()
    Messenger.PushMessage ("Getting information about sets...")

    for pSet in FlickrStore.GetPhotosets ():
      _photoSetQueue.Enqueue (pSet)

  private def FillItemsQueue ():
    # FIXME Wrap exception here
    # Validate all filenames and add the candidates
    for item as DownloadItem in _itemsList:
      item.ValidateFilename ()
      Database.AddCandidate (item)
      _itemsQueue.Enqueue (item)

  private def ProcessItemsQueue ():
    threads = []
    try:
      # Update the progress-bar 
      Messenger.Reset ()
      Messenger.DefineProgressRange (_itemsQueue.Count)
      Messenger.PushMessage ("Downloading {0} photos...", _itemsQueue.Count)

      # Start the item worker threads
      for i in range (0, 3):
        threads.Add (NewItemWorker ())
    except:
      # FIXME Wrap exception here
      raise
    ensure:
      # Wait for all the worker threads to finish
      WaitForThreadListToJoin (threads)

    lock _locker:
      raise _workerException if _workerException

  private def SyncThreadStart ():
    try:
      # Create the storage objects
      _photoSetQueue = Queue ()
      _itemsQueue = Queue ()
      _itemsList = []
      _workerException = null

      # Check out our database
      Database.SyncToStorage ()

      # We can safely set the old sync dir here
      Config.PreviousPhotosDirectory = Config.PhotosDirectory

      # Main logic
      FillPhotosetQueue ()
      ProcessPhotosetQueue ()
      FillItemsQueue ()
      ProcessItemsQueue ()
    except e as Exception:
      Error (null, e)
    ensure:
      _photoSetQueue = null
      _itemsQueue = null
      _itemsList = null
      Finished (null, null)

    lock _locker:
      _status = SyncStatus.Stopped
    
  private def WaitForThreadListToJoin (list):
    for thread as Thread in list:
      thread.Join ()
  
  private def NewPhotoSetWorker () as Thread:
    thread = Thread (PhotoSetWorker)
    thread.Start ()
    return thread

  private def NewItemWorker () as Thread:
    thread = Thread (ItemWorker)
    thread.Start ()
    return thread

  private def PhotoSetWorker ():
    try:
      while (true):
        task = null

        lock _locker:
          return if _status != SyncStatus.InProgress
          task = _photoSetQueue.Dequeue () if _photoSetQueue.Count > 0

        if task != null:
          photoSet = task as Photoset
        
          for p in FlickrStore.GetPhotosForPhotoset (photoSet):
            if not Database.HasPhoto (p.PhotoId, photoSet.PhotosetId):
              item = DownloadItem (p, photoSet, Config.PhotosDirectory)
          
              lock _locker:
                _itemsList.Add (item)
       
          Messenger.Progress ()
        else:
          return
    except e as Exception:
      # FIXME Wrap exception here
      lock _locker:
        _status = SyncStatus.AbortingOnError
        _workerException = e

  private def ItemWorker ():
    try:
      while (true):
        task = null

        lock _locker:
          return if _status != SyncStatus.InProgress
          task = _itemsQueue.Dequeue () if _itemsQueue.Count > 0

        if task != null:
          item = task as DownloadItem
          item.EnsureDirectory ()
          Messenger.PushThumbnail (item.DownloadThumbnail ())
          item.Download ()
          Database.AddPhoto (item)
          Messenger.Progress ()
        else:
          return
    except e as Exception:
      # FIXME Wrap exception here
      lock _locker:
        _status = SyncStatus.AbortingOnError
        _workerException = e

