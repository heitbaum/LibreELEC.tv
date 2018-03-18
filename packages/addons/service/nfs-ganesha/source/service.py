################################################################################
#      This file is part of LibreELEC - https://libreelec.tv
#      Copyright (C) 2017-present Team LibreELEC
#
#  LibreELEC is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 2 of the License, or
#  (at your option) any later version.
#
#  LibreELEC is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with LibreELEC.  If not, see <http://www.gnu.org/licenses/>.
################################################################################

import xbmc
import xbmcvfs
import xbmcaddon
from os import system


class MyMonitor(xbmc.Monitor):
    def __init__(self, *args, **kwargs):
        xbmc.Monitor.__init__(self)
    
    def onSettingsChanged(self):
        writeexports()


# addon
__addon__ = xbmcaddon.Addon(id='service.nfs-ganesha')
__addonpath__ = xbmc.translatePath(__addon__.getAddonInfo('path'))
__addonhome__ = xbmc.translatePath(__addon__.getAddonInfo('profile'))
__scriptname__ = "nfs-ganesha"
__author__ = "lsellens"
__url__ = "https://github.com/lsellens/xbmc.addons"


def writeexports():
    shares = __addon__.getSetting("SHARES")
    file = xbmcvfs.File(xbmc.translatePath(__addonhome__ + 'config/ganesha.conf'), 'w')
    file.write('NFS_CORE_PARAM{NFS_Protocols=4;}\n')
    file.write('EXPORT_DEFAULTS{SecType=none;Protocols=4;Squash=All_Squash;Anonymous_uid=0;Anonymous_gid=0;}\n')
    for i in range(0, int(shares)):
        exec('folder{0} = __addon__.getSetting("SHARE_FOLDER{0}")'.format(i))
        exec('permission{0} = __addon__.getSetting("PERMISSION{0}")'.format(i))
        file.write('EXPORT{\n')
        file.write('Export_Id={0};Path="{1}";Pseudo="{1}";Access_Type={2};\n'.format(i+1, eval('folder{0}'.format(i)),
                                                                                     eval('permission{0}'.format(i))))
        file.write('FSAL{Name=VFS;}}\n')
    file.close()
    system("systemctl reload service.nfs-ganesha.service")


if not xbmcvfs.exists(xbmc.translatePath(__addonhome__ + 'config/ganesha.conf')):
    writeexports()

monitor = MyMonitor()
while not monitor.abortRequested():
    if monitor.waitForAbort():
        break

