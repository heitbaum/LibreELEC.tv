# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2022-present Team LibreELEC (https://libreelec.tv)

import xbmc
import xbmcvfs
import xbmcaddon
from os import system


class MyMonitor(xbmc.Monitor):
    def __init__(self, *args, **kwargs):
        xbmc.Monitor.__init__(self)

    def onSettingsChanged(self):
        writeconfig()


# addon
__addon__ = xbmcaddon.Addon(id='service.zabbix-agent')
__addonpath__ = xbmcvfs.translatePath(__addon__.getAddonInfo('path'))
__addonhome__ = xbmcvfs.translatePath(__addon__.getAddonInfo('profile'))
if not xbmcvfs.exists(xbmcvfs.translatePath(__addonhome__ + 'etc/')):
    xbmcvfs.mkdirs(xbmcvfs.translatePath(__addonhome__ + 'etc/'))
config = xbmcvfs.translatePath(__addonhome__ + 'etc/zabbix_agent.conf')
persistent = xbmcvfs.translatePath(__addonhome__ + 'zabbix_agent.conf')
if not xbmcvfs.exists(xbmcvfs.translatePath(__addonhome__ + 'etc/zabbix_agent.conf.d/')):
    xbmcvfs.mkdirs(xbmcvfs.translatePath(__addonhome__ + 'etc/zabbix_agent.conf.d/'))


def writeconfig():
    system("systemctl stop service.zabbix-agent.service")
    server = __addon__.getSetting("SERVER")
    listenport = __addon__.getSetting("LISTENPORT")
    serveractive = __addon__.getSetting("SERVERACTIVE")
    hostname = __addon__.getSetting("HOSTNAME")
    user = __addon__.getSetting("USER")

    if xbmcvfs.exists(persistent):
        xbmcvfs.delete(persistent)

    file = xbmcvfs.File(config, 'w')
    file.write('Server={}\n'.format(server))
    file.write('ListenPort={}\n'.format(listenport))
    file.write('ServerActive={}\n'.format(serveractive))
    file.write('Hostname={}\n'.format(hostname))
    file.write('User={}\n'.format(user))
    file.write('LogType=system\n')
    file.write('Include={}.d/*.conf\n'.format(config))

    file.close()
    system("systemctl start service.zabbix-agent.service")


if not xbmcvfs.exists(config):
    writeconfig()

monitor = MyMonitor()
while not monitor.abortRequested():
    if monitor.waitForAbort():
        break
