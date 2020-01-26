"""
DeepLabCut2.0 Toolbox (deeplabcut.org)
© A. & M. Mathis Labs
https://github.com/AlexEMG/DeepLabCut
Please see AUTHORS for contributors.

https://github.com/AlexEMG/DeepLabCut/blob/master/AUTHORS
Licensed under GNU Lesser General Public License v3.0
"""

from __future__ import print_function
import wx
import cv2
import matplotlib
import argparse

import matplotlib.pyplot as plt
from matplotlib import patches
from matplotlib.figure import Figure
from matplotlib.backends.backend_wxagg import FigureCanvasWxAgg as FigureCanvas
from matplotlib.widgets import RectangleSelector
import numpy as np

# ###########################################################################
# Class for GUI MainFrame
# ###########################################################################
from moviepy.video.io.VideoFileClip import VideoFileClip

from deeplabcut.generate_training_dataset import auxfun_drag_label, img_as_ubyte, Path, make_axes_locatable, \
    NavigationToolbar


class ImagePanel(wx.Panel):

    def __init__(self, parent,gui_size,**kwargs):
        h=gui_size[0]/2
        w=gui_size[1]/3
        wx.Panel.__init__(self, parent, -1,style=wx.SUNKEN_BORDER,size=(h,w))

        self.figure = matplotlib.figure.Figure()
        self.axes = self.figure.add_subplot(1, 1, 1)
        self.canvas = FigureCanvas(self, -1, self.figure)
        self.orig_xlim = None
        self.orig_ylim = None
        self.sizer = wx.BoxSizer(wx.VERTICAL)
        self.sizer.Add(self.canvas, 1, wx.LEFT | wx.TOP | wx.GROW)
        self.SetSizer(self.sizer)
        self.Fit()

    def getfigure(self):
        return(self.figure)

    def drawplot(self,img,keep_view=False):
        xlim = self.axes.get_xlim()
        ylim = self.axes.get_ylim()
        self.axes.clear()

        # convert the image to RGB as you are showing the image with matplotlib
        #im = cv2.imread(img)[...,::-1]
        ax = self.axes.imshow(img)
        self.orig_xlim = self.axes.get_xlim()
        self.orig_ylim = self.axes.get_ylim()
        divider = make_axes_locatable(self.axes)
        if keep_view:
            self.axes.set_xlim(xlim)
            self.axes.set_ylim(ylim)
        self.toolbar = NavigationToolbar(self.canvas)
        return(self.figure,self.axes,self.canvas,self.toolbar)

    def resetView(self):
        self.axes.set_xlim(self.orig_xlim)
        self.axes.set_ylim(self.orig_ylim)



class WidgetPanel(wx.Panel):
    def __init__(self, parent):
        wx.Panel.__init__(self, parent, -1,style=wx.SUNKEN_BORDER)

class MainFrame(wx.Frame):
    """Contains the main GUI and button boxes"""

    def __init__(self, parent, video_fnames, title, init_coords=None):
# Settting the GUI size and panels design
        self.coords=init_coords
        self.currentCoords=init_coords
        self.drs=None

        self.colormap = plt.get_cmap('hsv')
        displays = (wx.Display(i) for i in range(wx.Display.GetCount())) # Gets the number of displays
        screenSizes = [display.GetGeometry().GetSize() for display in displays] # Gets the size of each display
        index = 0 # For display 1.
        screenWidth = screenSizes[index][0]
        screenHeight = screenSizes[index][1]
        self.gui_size = (screenWidth*0.7,screenHeight*0.85)

        wx.Frame.__init__ ( self, parent, id = wx.ID_ANY, title = title,
                            size = wx.Size(self.gui_size), pos = wx.DefaultPosition, style = wx.RESIZE_BORDER|wx.DEFAULT_FRAME_STYLE|wx.TAB_TRAVERSAL )
        self.statusbar = self.CreateStatusBar()
        self.statusbar.SetStatusText("")

        self.SetSizeHints(wx.Size(self.gui_size)) #  This sets the minimum size of the GUI. It can scale now!

###################################################################################################################################################
# Spliting the frame into top and bottom panels. Bottom panels contains the widgets. The top panel is for showing images and plotting!
        topSplitter = wx.SplitterWindow(self)

        self.image_panel = ImagePanel(topSplitter, self.gui_size)
        self.widget_panel = WidgetPanel(topSplitter)

        topSplitter.SplitHorizontally(self.image_panel, self.widget_panel,sashPosition=self.gui_size[1]*0.83)#0.9
        topSplitter.SetSashGravity(1)
        sizer = wx.BoxSizer(wx.VERTICAL)
        sizer.Add(topSplitter, 1, wx.EXPAND)
        self.SetSizer(sizer)

###################################################################################################################################################
# Add Buttons to the WidgetPanel and bind them to their respective functions.

        widgetsizer = wx.WrapSizer(orient=wx.HORIZONTAL)

        self.prev_video = wx.Button(self.widget_panel, id=wx.ID_ANY, label='<<Previous Video')
        widgetsizer.Add(self.prev_video , 1, wx.ALL, 15)
        self.prev_video.Bind(wx.EVT_BUTTON, self.prevVideo)
        self.prev_video.Enable(False)

        self.next_video = wx.Button(self.widget_panel, id=wx.ID_ANY, label="Next Video>>")
        widgetsizer.Add(self.next_video , 1, wx.ALL, 15)
        self.next_video.Bind(wx.EVT_BUTTON, self.nextVideo)

        self.prev = wx.Button(self.widget_panel, id=wx.ID_ANY, label="<<Previous")
        widgetsizer.Add(self.prev , 1, wx.ALL, 15)
        self.prev.Bind(wx.EVT_BUTTON, self.prevImage)
        self.prev.Enable(False)

        self.next = wx.Button(self.widget_panel, id=wx.ID_ANY, label="Next>>")
        widgetsizer.Add(self.next , 1, wx.ALL, 15)
        self.next.Bind(wx.EVT_BUTTON, self.nextImage)

        self.zoom = wx.ToggleButton(self.widget_panel, label="Zoom")
        widgetsizer.Add(self.zoom , 1, wx.ALL, 15)
        self.zoom.Bind(wx.EVT_TOGGLEBUTTON, self.zoomButton)
        self.widget_panel.SetSizer(widgetsizer)

        self.home = wx.Button(self.widget_panel, id=wx.ID_ANY, label="Home")
        widgetsizer.Add(self.home , 1, wx.ALL,15)
        self.home.Bind(wx.EVT_BUTTON, self.homeButton)
        self.widget_panel.SetSizer(widgetsizer)

        self.pan = wx.ToggleButton(self.widget_panel, id=wx.ID_ANY, label="Pan")
        widgetsizer.Add(self.pan , 1, wx.ALL, 15)
        self.pan.Bind(wx.EVT_TOGGLEBUTTON, self.panButton)
        self.widget_panel.SetSizer(widgetsizer)

        self.lock = wx.CheckBox(self.widget_panel, id=wx.ID_ANY, label="Lock View")
        widgetsizer.Add(self.lock, 1, wx.ALL, 15)
        self.lock.Bind(wx.EVT_CHECKBOX, self.lockChecked)
        self.widget_panel.SetSizer(widgetsizer)

        self.quit = wx.Button(self.widget_panel, id=wx.ID_ANY, label="Save parameters and Quit")
        widgetsizer.Add(self.quit , 1, wx.ALL, 15)
        self.quit.Bind(wx.EVT_BUTTON, self.quitButton)

        self.widget_panel.SetSizer(widgetsizer)
        self.widget_panel.SetSizerAndFit(widgetsizer)
        self.widget_panel.Layout()

# Variables initialization
        self.video_fnames=video_fnames
        self.video_idx=0
        self.clip= VideoFileClip(self.video_fnames[self.video_idx])
        self.clip.reader.initialize()
        self.image = img_as_ubyte(self.clip.reader.read_frame())
        self.images=[self.image]
        self.images.append(img_as_ubyte(self.clip.reader.read_frame()))
        self.image_idx=0
        self.view_locked=False
        self.prezoom_xlim=[]
        self.prezoom_ylim=[]
        self.figure,self.axes,self.canvas,self.toolbar = self.image_panel.drawplot(self.image)
        self.axes.callbacks.connect('xlim_changed', self.onZoom)
        self.axes.callbacks.connect('ylim_changed', self.onZoom)
        self.canvas.mpl_connect('button_release_event', self.onButtonRelease)
        self.plot(self.image)

    def quitButton(self, event):
        """
        Quits the GUI
        """
        self.clip.close()
        self.statusbar.SetStatusText("")
        #dlg = wx.MessageDialog(None,"Are you sure?", "Quit!",wx.YES_NO | wx.ICON_WARNING)
        #result = dlg.ShowModal()
        #if result == wx.ID_YES:
        self.Destroy()

    def homeButton(self,event):
        self.image_panel.resetView()
        self.figure.canvas.draw()
        self.updateZoomPan()
        self.zoom.SetValue(False)
        self.pan.SetValue(False)
        self.statusbar.SetStatusText("")

    def panButton(self,event):
        if self.pan.GetValue() == True:
            self.toolbar.pan()
            self.statusbar.SetStatusText("Pan On")
            self.zoom.SetValue(False)
        else:
            self.toolbar.pan()
            self.statusbar.SetStatusText("Pan Off")

    def zoomButton(self, event):
        if self.zoom.GetValue() == True:
            # Save pre-zoom xlim and ylim values
            self.prezoom_xlim=self.axes.get_xlim()
            self.prezoom_ylim=self.axes.get_ylim()
            self.toolbar.zoom()
            self.statusbar.SetStatusText("Zoom On")
            self.pan.SetValue(False)
        else:
            self.toolbar.zoom()
            self.statusbar.SetStatusText("Zoom Off")

    def onZoom(self, ax):
        # See if axis limits have actually changed
        curr_xlim=self.axes.get_xlim()
        curr_ylim=self.axes.get_ylim()
        if self.zoom.GetValue() and not (self.prezoom_xlim[0]==curr_xlim[0] and self.prezoom_xlim[1]==curr_xlim[1] and self.prezoom_ylim[0]==curr_ylim[0] and self.prezoom_ylim[1]==curr_ylim[1]):
            self.updateZoomPan()
            self.statusbar.SetStatusText("Zoom Off")

    def onButtonRelease(self, event):
        if self.pan.GetValue():
            self.updateZoomPan()
            self.statusbar.SetStatusText("Pan Off")

    def lockChecked(self, event):
        self.cb = event.GetEventObject()
        self.view_locked=self.cb.GetValue()

    def show_image(self):
        self.figure,self.axes,self.canvas = self.image_panel.getfigure()
        #frame=cv2.cvtColor(self.image, cv2.COLOR_BGR2RGB)
        #frame=cv2.imread(self.image)[...,::-1]
        frame=self.image
        self.ax = self.axes.imshow(frame)
        #self.cid=self.figure.canvas.mpl_connect('button_press_event', self.onclick_callback)

    def prevVideo(self, event):
        self.video_idx=self.video_idx-1
        if self.video_idx==0:
            self.prev_video.Enable(False)
        self.next_video.Enable(True)
        self.next.Enable(True)
        self.prev.Enable(False)

        # Checks if zoom/pan button is ON
        self.updateZoomPan()

        self.clip.close()
        self.clip = VideoFileClip(self.video_fnames[self.video_idx])
        self.clip.reader.initialize()

        self.image = img_as_ubyte(self.clip.reader.read_frame())
        self.images = [self.image]
        self.images.append(img_as_ubyte(self.clip.reader.read_frame()))
        self.image_idx = 0

        self.figure, self.axes, self.canvas, self.toolbar = self.image_panel.drawplot(self.image,
                                                                                      keep_view=self.view_locked)
        self.axes.callbacks.connect('xlim_changed', self.onZoom)
        self.axes.callbacks.connect('ylim_changed', self.onZoom)

        self.plot( self.image)
        # self.cidClick = self.canvas.mpl_connect('button_press_event', self.onClick)
        self.canvas.mpl_connect('button_release_event', self.onButtonRelease)
        # MainFrame.saveEachImage(self)

    def nextVideo(self, event):
        self.video_idx=self.video_idx+1
        if self.video_idx==len(self.video_fnames)-1:
            self.next_video.Enable(False)
        self.prev_video.Enable(True)
        self.next.Enable(True)
        self.prev.Enable(False)

        # Checks if zoom/pan button is ON
        self.updateZoomPan()

        self.clip.close()
        self.clip=VideoFileClip(self.video_fnames[self.video_idx])
        self.clip.reader.initialize()

        self.image = img_as_ubyte(self.clip.reader.read_frame())
        self.images = [self.image]
        self.images.append(img_as_ubyte(self.clip.reader.read_frame()))
        self.image_idx = 0

        self.figure, self.axes, self.canvas, self.toolbar = self.image_panel.drawplot(self.image, keep_view=self.view_locked)

        self.axes.callbacks.connect('xlim_changed', self.onZoom)
        self.axes.callbacks.connect('ylim_changed', self.onZoom)

        self.plot(self.image)
        # self.cidClick = self.canvas.mpl_connect('button_press_event', self.onClick)
        self.canvas.mpl_connect('button_release_event', self.onButtonRelease)

    def prevImage(self, event):
        """
        Checks the previous Image and enables user to move the annotations.
        """
        self.image_idx = self.image_idx - 1

        # Checks for the first image and disables the Previous button
        if self.image_idx == 0:
            self.prev.Enable(False)
            return
        self.next.Enable(True)

        # Checks if zoom/pan button is ON
        self.updateZoomPan()

        self.image = self.images[self.image_idx]
        self.figure, self.axes, self.canvas, self.toolbar = self.image_panel.drawplot(self.image, keep_view=self.view_locked)
        self.axes.callbacks.connect('xlim_changed', self.onZoom)
        self.axes.callbacks.connect('ylim_changed', self.onZoom)

        self.plot(self.image)
        #self.cidClick = self.canvas.mpl_connect('button_press_event', self.onClick)
        self.canvas.mpl_connect('button_release_event', self.onButtonRelease)
        #MainFrame.saveEachImage(self)

    def nextImage(self, event):
        """
        Checks the previous Image and enables user to move the annotations.
        """
        # Checks for the first image and disables the Previous button
        self.prev.Enable(True)

        # Checks if zoom/pan button is ON
        MainFrame.updateZoomPan(self)

        self.image_idx = self.image_idx + 1
        self.image=self.images[self.image_idx]
        next_img=img_as_ubyte(self.clip.reader.read_frame())
        if not np.all(next_img==self.image):
            self.images.append(next_img)
        else:
            self.next.Enable(False)

        self.figure, self.axes, self.canvas, self.toolbar = self.image_panel.drawplot(self.image, keep_view=self.view_locked)
        self.axes.callbacks.connect('xlim_changed', self.onZoom)
        self.axes.callbacks.connect('ylim_changed', self.onZoom)

        self.plot( self.image)
        # self.cidClick = self.canvas.mpl_connect('button_press_event', self.onClick)
        self.canvas.mpl_connect('button_release_event', self.onButtonRelease)
        # MainFrame.saveEachImage(self)

    def plot(self,img):
        """
        Plots and call auxfun_drag class for moving and removing points.
        """
        if self.drs is not None:
            self.currentCoords=[]
            for dr in self.drs:
                self.currentCoords.append(dr.final_point)

        self.drs = []
        for coord_idx, coord in enumerate(self.currentCoords):
            color = self.colormap(coord_idx*20)
            circle = [
                patches.Circle((coord[0], coord[1]), radius=2, fc=color, alpha=1)]
            self.axes.add_patch(circle[0])
            dr = auxfun_drag_label.DraggablePoint(circle[0], '%d' % coord_idx)
            dr.connect()
            self.drs.append(dr)
        self.figure.canvas.draw()

    def updateZoomPan(self):
        # Checks if zoom/pan button is ON
        if self.pan.GetValue() == True:
            self.toolbar.pan()
            self.pan.SetValue(False)
        if self.zoom.GetValue() == True:
            self.toolbar.zoom()
            self.zoom.SetValue(False)
    #def onclick_callback(self, event):
    #    'eclick and erelease are the press and release events'
    #    global coords
    #    coords = [event.xdata, event.ydata]
    #    print(coords)
    #    self.coords = coords
    #    circle = patches.Circle(coords, radius=3, fc='r', alpha=.25)
    #    self.axes.add_patch(circle)
    #    self.figure.canvas.draw()
    #    return(self.coords)


def show(video_fnames, title, init_coords=None):
    app = wx.App()
    frame=MainFrame(None,video_fnames,title, init_coords=init_coords)
    frame.Show()
    app.MainLoop()
    updatedCoords = []
    for dr in frame.drs:
        updatedCoords.append((dr.final_point[0],dr.final_point[1]))
    return updatedCoords


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('config','image')
    cli_args = parser.parse_args()
