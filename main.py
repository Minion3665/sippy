import discord
import pyVoIP
from pyVoIP.VoIP import VoIPPhone, InvalidStateError, PhoneStatus
import os

import time

pyVoIP.DEBUG = True

def answer(call):
    try:
        print("Got a call...")
        call.answer()
        print("Answered...")
        time.sleep(5)
        print("Hanging up")
        call.hangup()
        print("Hung up")
    except InvalidStateError:
        pass

if __name__ == "__main__":
    phone = VoIPPhone(
        "sip.telnyx.com",
        5060,
        "banana",
        os.environ["SIP_PASS"],
        callCallback=answer,
    )
    phone.start()

    print("Registering")
    prev = phone.get_status()
    while phone.get_status() == PhoneStatus.REGISTERING:
        pass
    
    while True:
        curr = phone.get_status()

        if prev != curr:
            print(curr)
            prev = curr
    
    phone.stop()
# When we want to stop, phone.stop()
