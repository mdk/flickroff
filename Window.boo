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

class Window (Gtk.Window):

  _table as Table
  _progressBar as ProgressBar
  _directoryCaption as Label
  _directoryChooser as DirectoryChooserButton
  _syncButton as Button
  _abortButton as Button
  _buttonBox as HBox
  _photoCountLabel as Label
  _thumbnailArea as ThumbnailArea

  def constructor ():
    super ("Flickroff")
    BorderWidth = 12
    DeleteEvent += OnDeleteEvent

    mainHBox = HBox (false, 12)
    rightVBox = VBox (false, 6)
    leftVBox = VBox (false, 6)
    vbox = VBox (false, 6)

    _thumbnailArea = ThumbnailArea ()
    leftVBox.PackStart (_thumbnailArea, false, false, 0)

    syncTimeCaption = Label ("Last synchronization:")
    syncTimeLabel = Label ("Never")
    _directoryCaption = Label ("Photos location:")
    _directoryChooser = DirectoryChooserButton ()
    photoCountCaption = Label ("Photo count:")
    _photoCountLabel = Label ("123")

    syncTimeCaption.Xalign = 1.0
    syncTimeLabel.Xalign = 0.0
    _directoryCaption.Xalign = 1.0
    photoCountCaption.Xalign = 1.0
    _photoCountLabel.Xalign = 0.0

    _progressBar = SyncProgressBar ()
  
    _table = Table (2, 3, false)
    _table.ColumnSpacing = 6
    _table.RowSpacing = 6
    _table.Attach (syncTimeCaption, 0, 1, 0, 1)
    _table.Attach (syncTimeLabel, 1, 2, 0, 1)
    _table.Attach (photoCountCaption, 0, 1, 1, 2)
    _table.Attach (_photoCountLabel, 1, 2, 1, 2)
    _table.Attach (_directoryCaption, 0, 1, 2, 3)
    _table.Attach (_directoryChooser, 1, 2, 2, 3)

    _syncButton = Button ("Synchronize")
    _syncButton.Clicked += OnSynchronizeClicked

    _abortButton = Button ("Abort")
    _abortButton.Clicked += OnAbortClicked

    _buttonBox = HBox (false, 6)
    _buttonBox.PackStart (_progressBar, true, true, 0)
    _buttonBox.PackEnd (_syncButton, false, false, 0)

    rightVBox.Add (_table)
   
    mainHBox.PackStart (leftVBox, false, false, 0)
    mainHBox.PackEnd (rightVBox, true, true, 0)
    vbox.PackStart (mainHBox, false, false, 6)
    vbox.PackEnd (_buttonBox, false, false, 0)
    vbox.Spacing = 12
    vbox.ShowAll ()
    
    _progressBar.HideAll ()
    UpdatePhotoCount ()
    
    Add (vbox)
    SyncEngine.Error += OnSyncError
    SyncEngine.Finished += OnSyncFinished

  private def UpdatePhotoCount ():
    _photoCountLabel.Text = Database.GetPhotoCount ().ToString ()

  private def OnDeleteEvent ():
    Application.Quit ()

  private def OnSynchronizeClicked ():
    ShowProgressBar ()
    _directoryChooser.Sensitive = false
    movePhotos = false

    if Config.PhotosDirectory != Config.PreviousPhotosDirectory and Database.GetPhotoCount () > 0:
      moveQuestionDialog = CopyQuestionDialog (self)
      response = moveQuestionDialog.Run ()
      moveQuestionDialog.Destroy ()
      movePhotos = true if response == ResponseType.Yes

    if not FlickrStore.HasToken:
      authorizeDialog = AuthorizeDialog (self)
      response = authorizeDialog.Run ()
      authorizeDialog.Destroy ()
      return if response != ResponseType.Ok
      # FIXME Temporary
      FlickrStore.GetTokenForFrob (authorizeDialog.Frob)
    
    SyncEngine.StartSync (movePhotos)

  private def OnAbortClicked ():
    _abortButton.Sensitive = false;
    SyncEngine.Abort ()

  private def ShowProgressBar ():
    _progressBar.Show ()
    width = _syncButton.Requisition.Width
    _buttonBox.Remove (_syncButton)
    _buttonBox.PackEnd (_abortButton, false, false, 0)
    _abortButton.WidthRequest = width
    _abortButton.Show ()

  private def HideProgressBar ():
    _progressBar.Hide ()
    _buttonBox.Remove (_abortButton)
    _buttonBox.PackEnd (_syncButton, false, false, 0)
    _syncButton.Show ()

  private def OnSyncFinished ():
    try:
      Gdk.Threads.Enter ()
      _syncButton.Sensitive = true;
      _abortButton.Sensitive = true;
      _directoryChooser.Sensitive = true;
      HideProgressBar ();
      _thumbnailArea.ResetToLogo ()
    ensure:
      Gdk.Threads.Leave ()

  private def OnSyncError (o, e as Exception):
    print e
    try:
      Gdk.Threads.Enter ()
      dialog = SyncErrorDialog (self, e)
      dialog.ShowAll ()
      dialog.Run ()
      dialog.Destroy ()
    ensure:
      Gdk.Threads.Leave ()

