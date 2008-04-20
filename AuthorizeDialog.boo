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

class AuthorizeDialog (Dialog):

  _authorizeTask as AuthorizeTask
  _frob = ""

  Frob as string:
    get: 
      return _frob

  def constructor (window):
    super ("Authorize", window, DialogFlags.Modal)
    HasSeparator = false
    Resizable = false
    BorderWidth = 6

    icon = Image (Stock.DialogAuthentication, IconSize.Dialog)

    mainHBox = HBox (false, 12)
    rightVBox = VBox (false, 6)
    leftVBox = VBox (false, 6)
    buttonAlignementHBox = HButtonBox ()
    buttonAlignementHBox.Layout = ButtonBoxStyle.Spread

    messageOneLabel = CreateWrappedLabel ("Before you can sync your photos you need to " +
                                          "authorize this application to access your photos. " +
                                          "This program will access your Flickr account in <b>read</b> mode. ")
    messageTwoLabel = CreateWrappedLabel ("A Flickr website requiring you to login will open " +
                                          " in your web browser. Go ahead when done and authorized.")

    authorizeButton = Button ("Authorize through flickr")
    authorizeButton.Clicked += OnFlickrButtonClicked
    buttonAlignementHBox.Add (authorizeButton)

    rightVBox.PackStart (messageOneLabel, true, true, 0)
    rightVBox.PackStart (buttonAlignementHBox, false, false, 0)
    rightVBox.PackStart (messageTwoLabel, true, true, 0)

    leftVBox.PackStart (icon, false, false, 0)
    mainHBox.PackStart (leftVBox, false, false, 0)
    mainHBox.PackEnd (rightVBox, true, true, 0)
    VBox.PackStart (mainHBox, false, false, 6)
    VBox.Spacing = 12
    VBox.ShowAll ()

    # Dialog buttons
    AddButton (Stock.Ok, ResponseType.Ok);

  private def CreateWrappedLabel (msg as string) as Gtk.Label:
    label = Label (msg)
    label.Wrap = true
    label.UseMarkup = true
    label.LineWrap = true
    label.Xalign = 0.0
    return label

  private def OnFlickrButtonClicked ():
    VBox.Sensitive = false
    GdkWindow.Cursor = Gdk.Cursor (Gdk.CursorType.Watch)
    _authorizeTask = AuthorizeTask ()
    _authorizeTask.Finished += OnAuthorizeTaskFinished
    _authorizeTask.Start ()
   
  private def OnAuthorizeTaskFinished ():
    try:
      Gdk.Threads.Enter ()
      Gnome.Url.Show (_authorizeTask.Url)
      _frob = _authorizeTask.Frob
      _authorizeTask = null
      VBox.Sensitive = true
      GdkWindow.Cursor = null
    ensure:
      Gdk.Threads.Leave ()

