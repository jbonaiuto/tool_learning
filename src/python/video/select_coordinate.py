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

# ###########################################################################
# Class for GUI MainFrame
# ###########################################################################
from deeplabcut.generate_training_dataset import auxfun_drag_label


class ImagePanel(wx.Panel):

    def __init__(self, parent,gui_size,**kwargs):
        h=gui_size[0]/2
        w=gui_size[1]/3
        wx.Panel.__init__(self, parent, -1,style=wx.SUNKEN_BORDER,size=(h,w))

        self.figure = matplotlib.figure.Figure()
        self.axes = self.figure.add_subplot(1, 1, 1)
        self.canvas = FigureCanvas(self, -1, self.figure)
        self.sizer = wx.BoxSizer(wx.VERTICAL)
        self.sizer.Add(self.canvas, 1, wx.LEFT | wx.TOP | wx.GROW)
        self.SetSizer(self.sizer)
        self.Fit()

    def getfigure(self):
        """
        Returns the figure, axes and canvas
        """
        return(self.figure,self.axes,self.canvas)


class WidgetPanel(wx.Panel):
    def __init__(self, parent):
        wx.Panel.__init__(self, parent, -1,style=wx.SUNKEN_BORDER)

class MainFrame(wx.Frame):
    """Contains the main GUI and button boxes"""

    def __init__(self, parent,image, title, init_coords=None):
# Settting the GUI size and panels design
        self.coords=init_coords
        self.updatedCoords=init_coords
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

        self.help = wx.Button(self.widget_panel, id=wx.ID_ANY, label="Help")
        widgetsizer.Add(self.help , 1, wx.ALL, 15)
        self.help.Bind(wx.EVT_BUTTON, self.helpButton)

        self.quit = wx.Button(self.widget_panel, id=wx.ID_ANY, label="Save parameters and Quit")
        widgetsizer.Add(self.quit , 1, wx.ALL, 15)
        self.quit.Bind(wx.EVT_BUTTON, self.quitButton)

        self.widget_panel.SetSizer(widgetsizer)
        self.widget_panel.SetSizerAndFit(widgetsizer)
        self.widget_panel.Layout()

# Variables initialization
        self.image = image
        self.figure = Figure()
        self.axes = self.figure.add_subplot(111)
        self.show_image()
        self.plot(None)

    def quitButton(self, event):
        """
        Quits the GUI
        """
        self.statusbar.SetStatusText("")
        #dlg = wx.MessageDialog(None,"Are you sure?", "Quit!",wx.YES_NO | wx.ICON_WARNING)
        #result = dlg.ShowModal()
        #if result == wx.ID_YES:
        self.Destroy()

    def show_image(self):
        self.figure,self.axes,self.canvas = self.image_panel.getfigure()
        #frame=cv2.cvtColor(self.image, cv2.COLOR_BGR2RGB)
        #frame=cv2.imread(self.image)[...,::-1]
        frame=self.image
        self.ax = self.axes.imshow(frame)
        #self.cid=self.figure.canvas.mpl_connect('button_press_event', self.onclick_callback)


    def plot(self,img):
        """
        Plots and call auxfun_drag class for moving and removing points.
        """
        self.updatedCoords = []
        self.drs = []
        for coord_idx, coord in enumerate(self.coords):
            color = self.colormap(coord_idx*20)
            circle = [
                patches.Circle((coord[0], coord[1]), radius=2, fc=color, alpha=1)]
            self.axes.add_patch(circle[0])
            self.dr = auxfun_drag_label.DraggablePoint(circle[0], '%d' % coord_idx)
            self.dr.connect()
            self.drs.append(self.dr)
            self.updatedCoords.append(self.dr.coords[0])
        self.figure.canvas.draw()

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

    def helpButton(self,event):
        """
        Opens Instructions
        """
        wx.MessageBox('Click on image to select a coordinate.\n\n Click OK to continue', 'Instructions to use!', wx.OK | wx.ICON_INFORMATION)

def show(image, title, init_coords=None):
    app = wx.App()
    frame=MainFrame(None,image,title, init_coords=init_coords)
    frame.Show()
    app.MainLoop()
    return(frame.updatedCoords)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('config','image')
    cli_args = parser.parse_args()
