# SPDX-FileCopyrightText: 2025 Skyler Grey <sky@a.starrysky.fyi>
#
# SPDX-License-Identifier: AGPL-3.0-or-later

import pjsua2 as pj
import time
import os

class Account(pj.Account):
  def onRegState(self, prm):
      print("***OnRegState: " + prm.reason)

def main():
  ep_cfg = pj.EpConfig()
  ep = pj.Endpoint()
  ep.libCreate()
  ep.libInit(ep_cfg)

  sipTpConfig = pj.TransportConfig();
  sipTpConfig.port = 5060;
  ep.transportCreate(pj.PJSIP_TRANSPORT_UDP, sipTpConfig);
  ep.libStart();

  acfg = pj.AccountConfig();
  acfg.idUri = f"sip:{os.environ["SIP_USERNAME"]}@{os.environ["SIP_SERVER"]}";
  acfg.regConfig.registrarUri = f"sip:{os.environ["SIP_SERVER"]}";
  cred = pj.AuthCredInfo("digest", "*", os.environ["SIP_USERNAME"], 0, os.environ["SIP_PASSWORD"]);
  acfg.sipConfig.authCreds.append( cred );
  
  acc = Account();
  acc.create(acfg);

  call_param = pj.CallOpParam()
  call_param.opt.audioCount = 1
  call_param.opt.videoCount = 0
  c = pj.Call(acc, 1)
  c.makeCall("sip:a.starrysky.fyi@sip.linphone.org", call_param)

  while c.getInfo().state != pj.PJSIP_INV_STATE_DISCONNECTED:
    time.sleep(1)

  print("Call disconnected...")

  time.sleep(30)
  ep.libDestroy()

if __name__ == "__main__":
  main()
