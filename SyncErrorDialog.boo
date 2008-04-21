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

class SyncErrorDialog (MessageDialog):

  def constructor (window):

    # FIXME Move to static class part
    msg = ("An error occured during the sync process. " +
           "A very likely cause of that is a network access problem. " +
           "Please check your connectivity settings and status.")

    Console.WriteLine (msg)
    super (window, DialogFlags.Modal, MessageType.Error,
           ButtonsType.Ok, false, msg)

