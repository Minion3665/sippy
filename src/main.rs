use rvoip::client_core::{ClientConfig, ClientManager, MediaConfig};
use std::env;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let config = ClientConfig::new()
        .with_sip_addr(format!("0.0.0.0:{}", env::var("SIP_PORT").unwrap_or("5060".to_string())).parse()?)
        .with_media_addr("127.0.0.1:20000".parse()?)
        .with_media(MediaConfig::default());
    
    let client = ClientManager::new(config).await?;
    client.start().await?;
    
    // Make a call
    let call_id = client.make_call(
        "sip:testminion@0.0.0.0".to_string(),
        "sip:a.starrysky.fyi@sip.linphone.org".to_string(),
        None
    ).await?;
    
    println!("📞 Call initiated: {}", call_id);
    tokio::signal::ctrl_c().await?;
    Ok(())
}
