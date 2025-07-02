import asyncio

import PySIP
import PySIP.sip_account
import PySIP.sip_call

import PySIP.utils.logger

import os

import logging

formatter = logging.Formatter('%(filename)s:%(lineno)d - %(asctime)s - %(name)s - %(levelname)s - %(message)s')
PySIP.utils.logger.console_handler.setFormatter(formatter)

account = PySIP.sip_account.SipAccount(
    username = os.environ["SIP_USERNAME"],
    password = os.environ["SIP_PASSWORD"],
    hostname = f"{os.environ["SIP_SERVER"]}", # ":{os.environ.get("SIP_PORT", 5060)}",
    connection_type=os.environ.get("SIP_PROTOCOL", "AUTO"),
    caller_id="+447454584076", # TODO: change this to our real phone number..., telnyx will not work without it
)

@account.on_incoming_call
async def handle_incoming_call(call: PySIP.sip_call.SipCall):
    await call.accept()
    await call.call_handler.say("We have received your call successfully")
    await call.stop()

async def main():
    async def log(message):
        # Yes, this function does have to be async
        # Yes I know there are no awaits in it so it'll block anyway
        # This isn't JavaScript where you can just await undefined you know...
        print(f"Got SIP message: {message.status}@{message.type}: {message.data}")

    account.sip_core.on_message_callbacks.append(log)
    
    await account.register()
    print("Registered account...")

    account.__sip_client.realm = os.environ["SIP_SERVER"] # TODO: can we determine this from the sip headers we are given?

    call = account.make_call("a.starrysky.fyi") # Not sure how I call people on other servers - maybe doesn't matter if we always are calling out to sip.telnyx.com phone numbers...
    call_task = call.start()

    async def log_call_state():
        while True:
            print(call.call_state)
            await asyncio.sleep(5)

    log_task = log_call_state()
    speak_task = call.call_handler.say("I am calling you")

    await asyncio.gather(call_task, log_task, speak_task)

    print("Closing")
    await account.unregister()
    print("Closed")

asyncio.get_event_loop().create_task(main())
asyncio.get_event_loop().run_forever()
