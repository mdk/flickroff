Flickroff.exe: Database.boo Exceptions.boo Config.boo Flickroff.boo FlickrStore.boo SyncEngine.boo DownloadItem.boo Messenger.boo Window.boo SyncErrorDialog.boo AuthorizeDialog.boo AuthorizeTask.boo SyncProgressBar.boo ThumbnailArea.boo DirectoryChooserButton.boo CopyQuestionDialog.boo
	booc AuthorizeDialog.boo FlickrStore.boo Flickroff.boo Database.boo Exceptions.boo Config.boo DownloadItem.boo SyncEngine.boo Window.boo Messenger.boo SyncErrorDialog.boo AuthorizeTask.boo SyncProgressBar.boo ThumbnailArea.boo DirectoryChooserButton.boo CopyQuestionDialog.boo -out:Flickroff.exe `pkg-config --libs gconf-sharp-2.0 gtk-sharp-2.0 gnome-sharp-2.0` -r:Mono.Cairo

run: Flickroff.exe
	mono --debug Flickroff.exe

clean:
	rm -f *.exe
	rm -f *.mdb
