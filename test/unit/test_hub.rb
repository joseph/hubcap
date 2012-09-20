require 'test_helper'
require 'rubygems'
require 'capistrano'

class Hubcap::TestHub < Test::Unit::TestCase

  def test_hub
    hub = Hubcap.hub { application('example') }
    assert_equal(hub, hub.hub)
  end


  def test_history
    hub = Hubcap.hub { application('example') }
    assert_equal([], hub.history)
  end


  def test_configure_capistrano_in_agnostic_mode
    hub = Hubcap.hub {
      application('a') {
        group('g') {
          role(:baseline)
          server('s') { role(:everything) }
        }
      }
    }

    cap = Capistrano::Configuration.new
    cap.set(:hubcap_agnostic, true)
    hub.configure_capistrano(cap)

    assert_equal(hub, cap.hubcap)
    assert_not_nil(cap.find_task('servers:list'))
    assert_not_nil(cap.find_task('puppet:check'))
    assert_nil(cap.find_task('deploy:setup'))
    assert_equal('s', cap.roles[:baseline].servers.first.host)
    assert_equal('s', cap.roles[:everything].servers.first.host)
  end


  def test_configure_capistrano_in_application_mode
    hub = Hubcap.hub {
      application('a', :recipes => 'deploy') {
        group('g') {
          cap_set(:branch, 'deploy')
          role(:baseline)
          server('s') { role(:everything) }
        }
      }
    }

    cap = Capistrano::Configuration.new
    cap.set(:hubcap_agnostic, false)
    hub.configure_capistrano(cap)

    assert_equal('deploy', cap.branch)
    assert_not_nil(cap.find_task('deploy:setup'))
  end


  def test_configure_capistrano_in_application_mode_with_two_applications
    hub = Hubcap.hub {
      role(:baseline)
      application('a1') { server('s1') }
      application('a2') { server('s2') }
    }

    cap = Capistrano::Configuration.new
    cap.set(:hubcap_agnostic, false)
    assert_raises(Hubcap::ApplicationModeError::TooManyApplications) {
      hub.configure_capistrano(cap)
    }
  end


  def test_configure_capistrano_in_application_mode_with_no_applications
    hub = Hubcap.hub { server('s1') { role(:baseline) } }

    cap = Capistrano::Configuration.new
    cap.set(:hubcap_agnostic, false)
    assert_raises(Hubcap::ApplicationModeError::NoApplications) {
      hub.configure_capistrano(cap)
    }
  end


  def test_configure_capistrano_in_application_mode_with_no_applications
    hub = Hubcap.hub {
      cap_set(:foo => 'bar')
      server('s1') {
        cap_set(:foo => 'baz')
        role(:baseline)
      }
    }

    cap = Capistrano::Configuration.new
    cap.set(:hubcap_agnostic, false)
    assert_raises(Hubcap::ApplicationModeError::DuplicateSets) {
      hub.configure_capistrano(cap)
    }
  end

end
