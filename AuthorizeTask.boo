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

class AuthorizeTask ():

    _locker = Object ()
    _frob as string
    _url as string
    _thread as Thread

    event Finished as EventHandler
    event Error as EventHandler

    Frob as string:
      get:
        lock _locker:
          return _frob

    Url as string:
      get:
        lock _locker:
          return _url

    def constructor ():
      _thread = Thread (Runner)

    def Start ():
      _thread.Start ()

    private def Runner ():
      try:
        # Start by creating a frob
        frob = FlickrStore.GetFrob ()
        lock _locker:
          _frob = frob

        # Get a url for a frob
        url = FlickrStore.GetUrlForFrob (frob)
        lock _locker:
          _url = url
      except:
        Error (self, null)

      Finished (self, null)

