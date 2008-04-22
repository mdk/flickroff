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
import System.Collections
import Gtk
import Cairo

class ThumbnailArea (DrawingArea):

  _surfaceA as Surface
  _surfaceB as Surface
  _locker as System.Object
  _animationStart as long = 0
  _animationEnd as long = 0
  _pixbufQueue as Queue
  _timeout as uint
  _logoOn as bool

  def constructor ():
    Messenger.ThumbnailUpdate += OnThumbnailUpdated
    ExposeEvent += OnExpose
    WidthRequest = 79
    HeightRequest = 79
    _surfaceA = null
    _surfaceB = null
    _locker = System.Object ()
    _pixbufQueue = Queue ()
    _logoOn = true

  def ResetToLogo ():
    _surfaceA = null
    _surfaceB = null
    _pixbufQueue = Queue ()
    _logoOn = true
    EnsureTimeoutRemoved ()
    QueueDraw ()

  private def OnThumbnailUpdated (caller, thumbnail as Gdk.Pixbuf):
    try:
      Gdk.Threads.Enter ()
      lock _locker:
        using cairo = Gdk.CairoHelper.Create (GdkWindow):
          if _surfaceB == null:
            _surfaceB = PixbufToSurface (cairo, thumbnail)
            _animationStart = DateTime.Now.Ticks
            _animationEnd = _animationStart + 20000000
          else:
            _pixbufQueue.Enqueue (thumbnail)

          EnsureTimeoutPresent ()
    ensure:
      Gdk.Threads.Leave ()

  private def OnExpose ():
    lock _locker:
      using cairo = Gdk.CairoHelper.Create (GdkWindow) as Cairo.Context:

        if _surfaceA == null:
          _surfaceA = FullPixbufToSurface (cairo, Gdk.Pixbuf ("logo.png"))

        if _surfaceA != null and _surfaceB != null:
          alpha = CalculateAlpha (DateTime.Now.Ticks)
          
          cairo.SetSourceSurface (_surfaceA, 2, 2)
          cairo.PaintWithAlpha (1.0 - alpha)
  
          cairo.SetSourceSurface (_surfaceB, 2, 2)
          cairo.PaintWithAlpha (alpha)

          if not _logoOn:
            cairo.LineWidth = 1.0
            SketchRoundedRect (cairo, 2.4, 2.4, 75.0, 75.0, 8.0)
            cairo.SetSourceRGBA (0.0, 0.0, 0.0, 0.5)
            cairo.Stroke ()
          else:
            cairo.LineWidth = 1.0
            SketchRoundedRect (cairo, 2.4, 2.4, 75.0, 75.0, 8.0)
            cairo.SetSourceRGBA (0.0, 0.0, 0.0, 0.5 * alpha)
            cairo.Stroke ()

          if DateTime.Now.Ticks > _animationEnd:
            cast (IDisposable, _surfaceA).Dispose ()
            _surfaceA = _surfaceB
            _surfaceB = null
            _logoOn = false

            if _pixbufQueue.Count > 0:
              pixbuf = _pixbufQueue.Dequeue () as Gdk.Pixbuf
              _surfaceB = PixbufToSurface (cairo, pixbuf)
              _animationStart = DateTime.Now.Ticks
              _animationEnd = _animationStart + 20000000
              EnsureTimeoutPresent ()
            else:
              EnsureTimeoutRemoved ()
            
        elif _surfaceA != null:
          cairo.SetSourceSurface (_surfaceA, 2, 2)
          cairo.Paint ()

          if not _logoOn:
            cairo.LineWidth = 1.0
            SketchRoundedRect (cairo, 2.4, 2.4, 75.0, 75.0, 8.0)
            cairo.SetSourceRGBA (0.0, 0.0, 0.0, 0.5)
            cairo.Stroke ()

  private def PixbufToSurface (cairo as Context, pixbuf as Gdk.Pixbuf) as Surface:
    surface = cairo.Target.CreateSimilar (Content.ColorAlpha, 75, 75)
    using new_cairo = Context (surface):
      Gdk.CairoHelper.SetSourcePixbuf (new_cairo, pixbuf, 0.0, 0.0)
      SketchRoundedRect (new_cairo, 0.0, 0.0, 75.0, 75.0, 8.0)
      new_cairo.Fill ()
      return surface

  private def FullPixbufToSurface (cairo as Context, pixbuf as Gdk.Pixbuf) as Surface:
    surface = cairo.Target.CreateSimilar (Content.ColorAlpha, 75, 75)
    using new_cairo = Context (surface):
      Gdk.CairoHelper.SetSourcePixbuf (new_cairo, pixbuf, 0.0, 0.0)
      new_cairo.Paint ()
      return surface

  private def SketchRoundedRect (cairo as Context, x0 as double, y0 as double, width as double, height as double, radius as double):
    x1 = x0 + width
    y1 = y0 + height

    radius = width / 2 if width / 2 < radius
    radius = height / 2 if height / 2 < radius
    half_radius = radius / 2

    cairo.MoveTo (x0, y0 + radius)
    cairo.CurveTo (x0, y0 + half_radius, x0 + half_radius, y0, x0 + radius, y0)
    cairo.LineTo (x1 - radius, y0)
    cairo.CurveTo (x1 - half_radius, y0, x1, y0 + half_radius, x1, y0 + radius);
    cairo.LineTo (x1, y1 - radius);
    cairo.CurveTo (x1, y1 - half_radius, x1 - half_radius, y1, x1 - radius, y1);
    cairo.LineTo (x0 + radius, y1);
    cairo.CurveTo (x0 + half_radius, y1, x0, y1 - half_radius, x0, y1 - radius);
    cairo.ClosePath ()

  private def CalculateAlpha (time as long) as double:
    time = _animationEnd if time > _animationEnd
    time = _animationStart if time < _animationStart
    off = time - _animationStart
    return cast (double, off) / (cast (double, _animationEnd) - cast (double, _animationStart))

  private def OnTimeout () as bool:
    try:
      Gdk.Threads.Enter ()
      QueueDraw ()
      return true
    ensure:
      Gdk.Threads.Leave ()

  private def EnsureTimeoutPresent ():
    return if _timeout != 0
    _timeout = GLib.Timeout.Add (40, OnTimeout)

  private def EnsureTimeoutRemoved ():
    return if _timeout == 0
    GLib.Source.Remove (_timeout)
    _timeout = 0


