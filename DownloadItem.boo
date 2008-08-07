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
import System.IO
import System.Net
import FlickrNet

class DownloadItem ():

  _thumbnailUrl as string
  _shortDirectory as string
  static locker = Object ()

  [Property (Url)]
  _url as string

  [Property (Filename)]
  _filename as string

  [Property (Directory)]
  _directory as string

  [Property (Extension)]
  _extension as string

  [Property (PhotoId)]
  _photoId as string

  [Property (PhotosetId)]
  _photosetId as string

  FullPath as string:
    get:
      return Path.Combine (_directory, _filename + _extension)

  ShortPath as string:
    get:
      return Path.Combine (_shortDirectory, _filename + _extension)

  def constructor (photo as Photo, photoset as Photoset, directory as string):
    # FIXME No need to pre-declare vars here?
    _filename = photo.Title
    
    if photoset != null:
      _directory = Path.Combine (directory, photoset.Title)
      _photosetId = photoset.PhotosetId
      _shortDirectory = photoset.Title
    else:
      _photosetId = "-1"
      _directory = directory
      _shortDirectory = ""

    _photoId = photo.PhotoId
    _url = FlickrStore.GetOriginalPhotoUrl (photo)
    _extension = Path.GetExtension (_url)
    _thumbnailUrl = photo.SquareThumbnailUrl

  def EnsureDirectory ():
    lock locker:
      System.IO.Directory.CreateDirectory (_directory) if not System.IO.Directory.Exists (_directory)

  def ValidateFilename ():
    # Get rid of some invalid characters
    for c in Path.GetInvalidFileNameChars ():
      _filename = _filename.Replace (c, char ('-'))

    origname = _filename
    number = 2
    while (Database.HasLocation (ShortPath) == true):
      _filename = origname + String.Format (" ({0})", number)
      number += 1

  def Download ():
    try:
      request = WebRequest.Create (_url)
      request.Timeout = 100000
      inputStream = request.GetResponse ().GetResponseStream ()
      outputStream = File.Create (FullPath)
      buf = array (byte, 1024)
      c = 0

      while ((c = inputStream.Read (buf, 0, 1024)) != 0):
        outputStream.Write (buf, 0, c)

      inputStream.Close ()
      outputStream.Close ()
    except:
      File.Delete (FullPath)
      raise

  def DownloadThumbnail () as Gdk.Pixbuf:
    request = WebRequest.Create (_thumbnailUrl)
    inputStream = request.GetResponse ().GetResponseStream ()
    pixbuf = Gdk.Pixbuf (inputStream)
    inputStream.Close ()
    return pixbuf

  override def ToString ():
    return String.Format ("{0} => {1}", _url, FullPath)


