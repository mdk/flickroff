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

class DirectoryChooserButton (Gtk.FileChooserButton):

  def constructor ():
    super (null)
    Action = FileChooserAction.SelectFolder

    # By default set to config and create if not present
    if not System.IO.Directory.Exists (Config.PhotosDirectory):
      # FIXME Log something here through Messenger?
      System.IO.Directory.CreateDirectory (Config.PhotosDirectory)

    SetCurrentFolder (Config.PhotosDirectory)

  protected def OnCurrentFolderChanged ():
    Config.PhotosDirectory = CurrentFolder

