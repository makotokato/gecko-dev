# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from __future__ import absolute_import

import os

config = {
    "stage_platform": "linux-fuzzing-debug",
    "debug_build": True,
    #### 32 bit build specific #####
    "env": {
        "MOZBUILD_STATE_PATH": os.path.join(os.getcwd(), ".mozbuild"),
        "DISPLAY": ":2",
        "HG_SHARE_BASE_DIR": "/builds/hg-shared",
        "MOZ_OBJDIR": "%(abs_obj_dir)s",
        "MOZ_CRASHREPORTER_NO_REPORT": "1",
        "LC_ALL": "C",
        "XPCOM_DEBUG_BREAK": "stack-and-abort",
        # 32 bit specific
        "PATH": "/usr/local/bin:/bin:\
/usr/bin:/usr/local/sbin:/usr/sbin:/sbin",
        "LD_LIBRARY_PATH": "%(abs_obj_dir)s/dist/bin",
        "TINDERBOX_OUTPUT": "1",
    },
    #######################
}
