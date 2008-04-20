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
import Gtk

#GLib.Thread.Init ()
Gdk.Threads.Init ()
Application.Init ()
Messenger.Init ()
Config.Initialize ()
Database.Initialize ()
FlickrStore.Initialize ()
SyncEngine.Init ()

#if not FlickrStore.HasToken:
#  frob = FlickrStore.GetFrob ()
#  print "Go to:", FlickrStore.GetUrlForFrob (frob)
#  Console.ReadLine ()
#  FlickrStore.GetTokenForFrob (frob)

window = Flickroff.Window ()
window.Show ()

Application.Run ()

#print "Will download:"
#SyncEngine.PerformFullSync ()
