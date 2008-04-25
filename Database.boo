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
import System.Data
import Mono.Data.SqliteClient;

static class Database ():

  _connection as SqliteConnection
  _locker as Object
  _candidatesList as List

  def Initialize ():
    _candidatesList = []
    _locker = Object ()
    _connection = SqliteConnection (GetAndCreateDatabaseUri ())
    _connection.Open ()
    CreateTables () if not CheckDatabaseVersion ()

  def MovePhotosToNewLocation (newDir):
    # FIXME Need some error handling in this function
    if not System.IO.Directory.Exists (newDir):
      raise ReplaceMeException ("Can't find target directory")

    removalList = []
    currentPhotosDir = Config.PhotosDirectory
    cmd = _connection.CreateCommand ()
    cmd.CommandText = ("SELECT * FROM photos ")

    lock _locker:
      reader = cmd.ExecuteReader ()

      # For each photo in the db...
      while reader.Read ():
        oldPhotoPath = Path.Combine (currentPhotosDir, reader [3])
        newPhotoPath = Path.Combine (newDir, reader [3])

        if System.IO.File.Exists (oldPhotoPath):
          # If photo exists on the disk, move it
          subDir = System.IO.Path.GetDirectoryName (newPhotoPath)
          System.IO.Directory.CreateDirectory (subDir) if not System.IO.Directory.Exists (subDir)
          System.IO.File.Copy (oldPhotoPath, newPhotoPath, true)
        else:
          # Otherwise delete the entry from the database (add to remove list)
          removalList.Add (reader [0])

      # Now remove all the elements from the removal list
      for photoId as int in removalList:
        cmd = _connection.CreateCommand ()
        cmd.CommandText = ("DELETE FROM photos " +
                           "WHERE id = @id")

        p1 = cmd.CreateParameter ()
        p1.ParameterName = "@id"
        p1.Value = photoId
        cmd.Parameters.Add (p1)

        cmd.ExecuteNonQuery ()

  def HasLocation (location):
    cmd = _connection.CreateCommand ()
    cmd.CommandText = ("SELECT * FROM photos " +
                       "WHERE location = @location")
                      
    p1 = cmd.CreateParameter ()
    p1.ParameterName = "@location"
    p1.Value = location
    cmd.Parameters.Add (p1)

    lock _locker:
      reader = cmd.ExecuteReader ()
      return true if reader.Read ()
      for item as DownloadItem in _candidatesList:
        return true if item.ShortPath == location
      
      return false

  def AddCandidate (candidate):
    lock _locker:
      _candidatesList.Add (candidate)

  def HasPhoto (photoid, setid):
    # Hmm, I wish I new a little more about System.Data
    # FIXME Execute as non-query?
    # FIXME The parameter creation should be moved to separate helper funcs
    cmd = _connection.CreateCommand ()
    cmd.CommandText = ("SELECT * FROM photos " +
                       "WHERE photoid = @photoid AND " +
                       "setid = @setid")

    p1 = cmd.CreateParameter ()
    p1.ParameterName = "@photoid"
    p1.Value = photoid
    cmd.Parameters.Add (p1)

    p2 = cmd.CreateParameter ()
    p2.ParameterName = "@setid"
    p2.Value = setid
    cmd.Parameters.Add (p2)

    lock _locker:
      reader = cmd.ExecuteReader ()
      return reader.Read ()

  def AddPhoto (photo as DownloadItem):
    c = _connection.CreateCommand ()
    c.CommandText = ("INSERT INTO photos VALUES " +
                     "(null, @photoid, @setid, @location)")
    
    p1 = c.CreateParameter ()
    p1.ParameterName = "@photoid"
    p1.Value = photo.PhotoId
    c.Parameters.Add (p1)

    p2 = c.CreateParameter ()
    p2.ParameterName = "@setid"
    p2.Value = photo.PhotosetId
    c.Parameters.Add (p2)

    p3 = c.CreateParameter ()
    p3.ParameterName = "@location"
    p3.Value = photo.ShortPath
    c.Parameters.Add (p3)
    
    lock _locker:
      c.ExecuteNonQuery ()
      _candidatesList.Remove (photo) if _candidatesList.Contains (photo)

  def GetPhotoCount () as int:
    # FIXME Smarter way to do this without dumbly fetching all results?
    count = 0
    cmd = _connection.CreateCommand ()
    cmd.CommandText = ("SELECT * FROM photos ")
    reader = cmd.ExecuteReader ()
    while reader.Read ():
      count++

    return count

  private def GetAndCreateDatabaseUri () as string:
    userdir = Environment.GetEnvironmentVariable ('HOME')
    dbdir = Path.Combine (userdir, Path.Combine (".gnome2", "flickroff"))
    Directory.CreateDirectory (dbdir) if not Directory.Exists (dbdir)
    file = Path.Combine (dbdir, "photos.db")
    return String.Format ("URI=file:{0}", file)

  private def CheckDatabaseVersion () as bool:
    try:
      cmd = _connection.CreateCommand ()
      cmd.CommandText = "SELECT * FROM info"
      reader = cmd.ExecuteReader ()
      reader.Read ()
      raise IncompatibleDatabaseException (reader [0]) if reader [0] != 1
      return true
    
    except e as IncompatibleDatabaseException:
      raise e
    
    except e as Exception:
      return false

  private def CreateTables ():
    ExecuteCreateCommand ("CREATE TABLE info (version INTEGER)")
    ExecuteCreateCommand ("CREATE TABLE photos ("   +
                          "id INTEGER PRIMARY KEY," +
                          "photoid VARCHAR,"        +
                          "setid VARCHAR,"          +
                          "location VARCHAR)")

    # Put standard version number in the database
    ExecuteCreateCommand ("INSERT INTO info VALUES ('1')")

  private def ExecuteCreateCommand (c):
    cmd = _connection.CreateCommand ()
    cmd.CommandText = c
    cmd.ExecuteNonQuery ()
    
