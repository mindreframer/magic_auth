defmodule MagicAuth.ExampleConfigPlugTest do
  use ExUnit.Case, async: false

  alias MagicAuth.{Config, ExampleConfigPlug}

  describe "process-based configuration" do
    test "admin config overrides specific values" do
      # Simulate plug call
      ExampleConfigPlug.call(%Plug.Conn{}, config: :admin)

      # Verify ProcessTree config is used
      assert Config.one_time_password_length() == 8
      assert Config.one_time_password_expiration() == 15
      assert Config.remember_me() == false
      assert Config.rate_limit_enabled?() == true
    end

    test "customer config uses different values" do
      ExampleConfigPlug.call(%Plug.Conn{}, config: :customer)

      assert Config.one_time_password_length() == 6
      assert Config.one_time_password_expiration() == 5
      assert Config.remember_me() == true
      assert Config.rate_limit_enabled?() == true
    end

    test "vendor config has different settings" do
      ExampleConfigPlug.call(%Plug.Conn{}, config: :vendor)

      assert Config.one_time_password_length() == 10
      assert Config.one_time_password_expiration() == 30
      assert Config.remember_me() == true
      assert Config.rate_limit_enabled?() == false
    end

    test "unknown config falls back to Application config" do
      # Set Application config for comparison
      Application.put_env(:magic_auth, :one_time_password_length, 4)
      Application.put_env(:magic_auth, :remember_me, false)

      try do
        ExampleConfigPlug.call(%Plug.Conn{}, config: :unknown)

        # Should use Application config when ProcessTree config is nil
        assert Config.one_time_password_length() == 4
        assert Config.remember_me() == false
      after
        # Clean up
        Application.delete_env(:magic_auth, :one_time_password_length)
        Application.delete_env(:magic_auth, :remember_me)
      end
    end

    test "no process config falls back to Application config" do
      # Clear any process config
      Process.delete(:magic_auth_config)

      # Set Application config
      Application.put_env(:magic_auth, :one_time_password_length, 7)

      try do
        # Should use Application config when no ProcessTree config exists
        assert Config.one_time_password_length() == 7
      after
        Application.delete_env(:magic_auth, :one_time_password_length)
      end
    end
  end
end
