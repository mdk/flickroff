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

static class Messenger ():

  _locker as object
  _progressRange as single
  _progressValue as single
  _message as string

  event ProgressReset as EventHandler
  event ProgressUpdate as EventHandler
  event MessageUpdate as EventHandler
  event ThumbnailUpdate as ThumbnailHandler

  callable ThumbnailHandler (caller as object, thumbnail as Gdk.Pixbuf)

  ProgressFraction as single:
    get:
      lock _locker:
        return _progressValue / _progressRange

  Message as string:
    get:
      lock _locker:
        return _message

  def PushMessage (msg):
    lock _locker:
      Console.WriteLine (msg)
      _message = msg
    MessageUpdate (null, null)

  def PushMessage (f as string, *args as (object)):
    lock _locker:
      Console.WriteLine (f, *args)
      _message = String.Format (f, *args)
    MessageUpdate (null, null)

  def PushThumbnail (thumbnail as Gdk.Pixbuf):
    lock _locker:
      ThumbnailUpdate (null, thumbnail)

  def Progress ():
    lock _locker:
      _progressValue += 1 if _progressValue < _progressRange
      
    ProgressUpdate (null, null)

  def DefineProgressRange (r as single):
    lock _locker:
      _progressRange = r

    ProgressUpdate (null, null)

  def Reset ():
    lock _locker:
      _progressRange = 1.0
      _progressValue = 0.0
      _message = ""

    MessageUpdate (null, null)
    ProgressUpdate (null, null)

  def Init ():
    _locker = Object ()
    _progressRange = 1.0
    _progressValue = 0.0
    _message = ""
