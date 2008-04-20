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
import FlickrNet

static class FlickrStore ():

  _flickr as Flickr

  HasToken as bool:
    get:
      return false if _flickr.AuthToken == null
      return true

  def Initialize ():
    _flickr = Flickr ("346e3a9b94fb2195c2f9288534fb9864", "1758b49cce06594d")
    _flickr.AuthToken = Config.Token

  def GetFrob () as string:
    return _flickr.AuthGetFrob ()

  def GetUrlForFrob (frob) as string:
    return _flickr.AuthCalcUrl (frob, AuthLevel.Read)

  def GetTokenForFrob (frob):
    token = _flickr.AuthGetToken (frob).Token
    Config.Token = token
    _flickr.AuthToken = token

  def GetPhotosForPhotoset (photoset as Photoset) as (Photo):
    return _flickr.PhotosetsGetPhotos (photoset.PhotosetId).PhotoCollection
    
  def GetPhotosets () as (Photoset):
    return _flickr.PhotosetsGetList ().PhotosetCollection

  def GetPhotosNotInSet () as (Photo):
    return _flickr.PhotosGetNotInSet ().PhotoCollection

  def GetOriginalPhotoUrl (photo as Photo) as string:
    sizes = _flickr.PhotosGetSizes (photo.PhotoId)

    for size in sizes.SizeCollection:
      return size.Source if size.Label == "Original"

    raise Exception ("FIXME: No original size!")


