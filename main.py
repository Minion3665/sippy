import asyncio

import aiovoip
import random
import argparse

import os

import logging

breakpoint()

sip_config = {
    'srv_host': os.environ["SIP_SERVER"],
    'srv_port': int(os.environ.get("SIP_PORT", "5060")),
    'realm': os.environ["SIP_SERVER"], # Can we not get this from parsing messages?
    'user': os.environ["SIP_USERNAME"],
    'pwd': os.environ["SIP_PASSWORD"],
    'local_host': "0.0.0.0", # don't know how to caller ID so we don't show as at 0.0.0.0
    'local_port': random.randint(6001, 6100)
}

async def run_call(peer: aiovoip.peers.Peer, duration: int):
    call = await peer.invite(
        from_details=aiovoip.Contact.from_header('sip:{}@{}:{}'.format(
            sip_config['user'], sip_config['local_host'], sip_config['srv_port'])),
        to_details=aiovoip.Contact.from_header('sip:a.starrysky.fyi@{}:{}'.format(
            sip_config['srv_host'], sip_config['srv_port'])),
        password=sip_config['pwd'])

    async with call:
        async def reader():
            async for msg in call.wait_for_terminate():
                print(msg)
                print("CALL STATUS:", msg.status_code)
    
            print("CALL ESTABLISHED")
            await asyncio.sleep(duration)
            print("GOING AWAY...")

        await reader()

    print("CALL TERMINATED")


async def start(app, protocol, duration):
    if protocol is aiovoip.WS:
        peer = await app.connect(
            'ws://{}:{}'.format(sip_config['srv_host'], sip_config['srv_port']),
            protocol=protocol,
            local_addr=(sip_config['local_host'], sip_config['local_port']))
    else:
        peer = await app.connect(
            (sip_config['srv_host'], sip_config['srv_port']),
            protocol=protocol,
            local_addr=(sip_config['local_host'], sip_config['local_port']))

    await run_call(peer, duration)
    await app.close()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-p', '--protocol', default=os.environ.get("SIP_PROTOCOL", "UDP").lower())
    parser.add_argument('-d', '--duration', type=int, default=5)
    args = parser.parse_args()

    loop = asyncio.get_event_loop()
    app = aiovoip.Application(loop=loop)

    if args.protocol == 'udp':
        loop.run_until_complete(start(app, aiovoip.UDP, args.duration))
    elif args.protocol == 'tcp':
        loop.run_until_complete(start(app, aiovoip.TCP, args.duration))
    elif args.protocol == 'ws':
        loop.run_until_complete(start(app, aiovoip.WS, args.duration))
    else:
        raise RuntimeError("Unsupported protocol: {}".format(args.protocol))

    loop.close()


if __name__ == '__main__':
    logging.basicConfig(level=logging.DEBUG)
    main()
