defmodule MagicAuth.ExampleConfigPlug do
  @moduledoc """
  Example plug demonstrating how to configure MagicAuth per-request using ProcessTree.
  
  This plug sets process-local configuration that will be used by MagicAuth
  instead of the global Application configuration.
  
  ## Usage
  
  In your router:
  
      pipeline :admin do
        plug :browser
        plug MagicAuth.ExampleConfigPlug, config: :admin
        plug :fetch_magic_auth_session
      end
      
      pipeline :customer do
        plug :browser  
        plug MagicAuth.ExampleConfigPlug, config: :customer
        plug :fetch_magic_auth_session
      end
  """
  
  
  def init(opts), do: opts
  
  def call(conn, opts) do
    config_type = Keyword.get(opts, :config, :default)
    config = build_config(config_type)
    
    Process.put(:magic_auth_config, config)
    conn
  end
  
  # Example configurations for different contexts
  defp build_config(:admin) do
    %{
      # Use all defaults from Application config, but override specific values
      one_time_password_length: 8,  # Admin gets longer codes
      one_time_password_expiration: 15,  # Admin codes expire later
      remember_me: false,  # Admin sessions don't use remember me
      enable_rate_limit: true
    }
  end
  
  defp build_config(:customer) do
    %{
      one_time_password_length: 6,  # Standard length
      one_time_password_expiration: 5,  # Customer codes expire faster
      remember_me: true,  # Customers can use remember me
      enable_rate_limit: true
    }
  end
  
  defp build_config(:vendor) do
    %{
      one_time_password_length: 10,  # Vendor gets very long codes
      one_time_password_expiration: 30,  # Vendor codes last longer
      remember_me: true,
      enable_rate_limit: false  # Vendors bypass rate limiting
    }
  end
  
  defp build_config(_) do
    # Return nil to use Application config as fallback
    nil
  end
end