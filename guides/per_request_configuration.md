# Per-Request Configuration

Magic Auth supports per-request configuration, allowing you to use different authentication settings for different parts of your application. This is useful for multi-tenant applications, applications with different user types, or applications that serve multiple hosts with varying authentication requirements.

## How It Works

Magic Auth uses the ProcessTree library to provide process-local configuration that appears global to the current request and its child processes (including LiveView processes). When a configuration map is stored in the process dictionary with the key `:magic_auth_config`, Magic Auth will use those values instead of the global Application configuration.

## Basic Usage

### Step 1: Create a Configuration Plug

Create a plug that sets the configuration for specific request contexts:

```elixir
defmodule MyApp.AdminMagicAuthPlug do
  def init(opts), do: opts
  
  def call(conn, _opts) do
    config = %{
      one_time_password_length: 8,
      one_time_password_expiration: 15,
      remember_me: false,
      enable_rate_limit: true
    }
    
    Process.put(:magic_auth_config, config)
    conn
  end
end

defmodule MyApp.CustomerMagicAuthPlug do
  def init(opts), do: opts
  
  def call(conn, _opts) do
    config = %{
      one_time_password_length: 6,
      one_time_password_expiration: 5,
      remember_me: true,
      enable_rate_limit: true
    }
    
    Process.put(:magic_auth_config, config)
    conn
  end
end
```

### Step 2: Add Plugs to Router Pipelines

Add your configuration plugs to the appropriate pipelines in your router:

```elixir
defmodule MyAppWeb.Router do
  use Phoenix.Router
  use MagicAuth.Router

  pipeline :admin do
    plug :browser
    plug MyApp.AdminMagicAuthPlug
    plug :fetch_magic_auth_session
  end

  pipeline :customer do
    plug :browser
    plug MyApp.CustomerMagicAuthPlug
    plug :fetch_magic_auth_session
  end

  scope "/admin", MyAppWeb.Admin do
    pipe_through :admin
    magic_auth("/sessions")
  end

  scope "/", MyAppWeb do
    pipe_through :customer
    magic_auth("/auth")
  end
end
```

## Configuration Options

You can override any of the following configuration values on a per-request basis:

- `:repo` - The Ecto repository module
- `:router` - Your application's router module
- `:callbacks` - Module implementing MagicAuth callback functions
- `:endpoint` - Your Phoenix application's endpoint module
- `:remember_me_cookie` - Name of the remember me cookie
- `:get_user` - Function to retrieve user by ID
- `:repo_opts` - Options passed to repository calls
- `:one_time_password_length` - Length of generated codes
- `:one_time_password_expiration` - Expiration time in minutes
- `:remember_me` - Whether to enable remember me functionality
- `:session_validity_in_days` - How long sessions remain valid
- `:enable_rate_limit` - Whether to enable rate limiting

## Advanced Configuration

### Host-Based Configuration

You can create more sophisticated plugs that determine configuration based on the request host:

```elixir
defmodule MyApp.HostBasedMagicAuthPlug do
  def init(opts), do: opts
  
  def call(conn, _opts) do
    config = case conn.host do
      "admin." <> _ -> admin_config()
      "api." <> _ -> api_config()
      _ -> customer_config()
    end
    
    Process.put(:magic_auth_config, config)
    conn
  end
  
  defp admin_config do
    %{
      callbacks: MyApp.AdminMagicAuthCallbacks,
      one_time_password_length: 8,
      remember_me: false
    }
  end
  
  defp api_config do
    %{
      callbacks: MyApp.APIMagicAuthCallbacks,
      one_time_password_expiration: 2,
      enable_rate_limit: false
    }
  end
  
  defp customer_config do
    %{
      callbacks: MyApp.CustomerMagicAuthCallbacks,
      one_time_password_length: 6,
      remember_me: true
    }
  end
end
```

### Dynamic Configuration

You can also build configurations dynamically based on request parameters, session data, or database lookups:

```elixir
defmodule MyApp.TenantMagicAuthPlug do
  def init(opts), do: opts
  
  def call(conn, _opts) do
    tenant = get_tenant_from_subdomain(conn.host)
    
    config = %{
      callbacks: Module.concat([MyApp, tenant.name, MagicAuthCallbacks]),
      remember_me_cookie: "#{tenant.slug}_magic_auth_remember_me",
      one_time_password_length: tenant.security_settings.otp_length,
      one_time_password_expiration: tenant.security_settings.otp_expiration
    }
    
    Process.put(:magic_auth_config, config)
    conn
  end
  
  defp get_tenant_from_subdomain(host) do
    # Your tenant lookup logic here
  end
end
```

## LiveView Compatibility

Per-request configuration works seamlessly with LiveView because LiveView processes inherit the configuration from their parent request process. No additional setup is required.

## Fallback Behavior

If no per-request configuration is set, Magic Auth automatically falls back to the global Application configuration. This ensures backward compatibility with existing applications.

## Testing

When testing with per-request configuration, you can set the configuration directly in your tests:

```elixir
test "admin authentication with custom config" do
  config = %{
    one_time_password_length: 8,
    remember_me: false
  }
  
  Process.put(:magic_auth_config, config)
  
  # Your test code here
end
```

## Migration Guide

Existing applications will continue to work without any changes. To add per-request configuration:

1. Create configuration plugs for your different contexts
2. Add the plugs to your router pipelines before `:fetch_magic_auth_session`
3. Test that your configuration overrides work as expected

The per-request configuration only overrides the values you specify. Any values not included in the configuration map will fall back to the Application configuration.