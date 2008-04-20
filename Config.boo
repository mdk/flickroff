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
import GConf

static class Config:
  
  _client as Client
  _basePath = "/apps/flickroff/"
  _defaultPhotosDir

  PhotosDirectory as string:
    set:
      SetString ("photos_directory", value)
    get:
      return GetString ("photos_directory", _defaultPhotosDir)

  Token as string:
    set:
      SetString ("token", value)
    get:
      return GetString ("token", "")

  def Initialize ():
    _client = Client ()
    userdir = Environment.GetEnvironmentVariable ('HOME')
    _defaultPhotosDir = Path.Combine (userdir, "Flickr photos")

  private def GetString (path, default) as string:
    ret as string
    try:
      ret = _client.Get (_basePath + path) as string
      ret = default if ret == null
    except:
      ret = default

    return ret
      
  private def SetString (path, value):
    value = String.Empty if value == null
    try:
      _client.Set (_basePath + path, value)
    except:
      pass

