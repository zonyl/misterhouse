=begin comment

INITIAL CONFIGURATION
In user code:

   use Insteon::IOLinc;
   $io_device = new Insteon::IOLinc('12.34.56:01',$myPLM);
   $io_device_sensor = new Insteon::IOLinc('12.34.56:02',$myPLM);

In items.mht:

INSTEON_IOLINC, 12.34.56:01, io_device, io_group
INSTEON_IOLINC, 12.34.56:02, io_device_sensor, io_group

Where io_device is the relay and io_device_sensor is the sensor

BUGS


EXAMPLE USAGE

Creating the object:
   use Insteon::IOLinc;
   $io_device = new Insteon::IOLinc('12.34.56:01',$myPLM);
   $io_device_sensor = new Insteon::IOLinc('12.34.56:02',$myPLM);

Turning on a relay:
   $io_device->set('on');

Turning off a relay:
   $io_device->set('off');

Requesting sensor status: 
(shouldn't be needed as the sensor is linked to the PLM, and will update the PLM
on state changes)
   $io_device_sensor->request_status();
   
Print the Current Device Settings to the log:
   $io_device->get_operating_flag();

NOTES

This module works with the Insteon IOLinc device from Smarthome.

The state that the relay is in when the device is linked to the PLM matters if
you are using relay mode Momentary_A.  

=over
=cut

use strict;
use Insteon::BaseInsteon;

package Insteon::IOLinc;

@Insteon::IOLinc::ISA = ('Insteon::BaseDevice', 'Insteon::DeviceController');

my %operating_flags = (
   'program_lock_on' => '00',
   'program_lock_off' => '01',
   'led_on_during_tx' => '02',
   'led_off_during_tx' => '03',
   'relay_follows_input_on' => '04',
   'relay_follows_input_off' => '05',
   'momentary_a_on' => '06',
   'momentary_a_off' => '07',
   'led_off' => '08',
   'led_enabled' => '09',
   'key_beep_enabled' => '0a',
   'key_beep_off' => '0b',
   'x10_tx_on_when_off' => '0c',
   'x10_tx_on_when_on' => '0d',
   'invert_sensor_on' => '0e',
   'invert_sensor_off' => '0f',
   'x10_rx_on_is_off' => '10',
   'x10_rx_on_is_on' => '11',
   'momentary_b_on' => '12',
   'momentary_b_off' => '13',
   'momentary_c_on' => '14',
   'momentary_c_off' => '15',
);

my %message_types = (
	%Insteon::BaseDevice::message_types,
	extended_set_get => 0x2e
);

sub new 
{
	my ($class, $p_deviceid, $p_interface) = @_;
	my $self = new Insteon::BaseDevice($p_deviceid, $p_interface);
	$$self{operating_flags} = \%operating_flags;
	$$self{message_types} = \%message_types;
	bless $self, $class;
	if ($self->group ne '02' && !$self->is_root){
		::print_log("[Insteon::IOLinc] Warning IOLincs with more than "
			. " 1 input and 1 output are not yet supported by this code.");
	}
	if ($self->is_root){
		$$self{momentary_time} = 20;
		$$self{relay_linked} = 0;
		$$self{trigger_reverse} = 0;
		$$self{relay_mode} = 'Latching';
	}
	return $self;
}

sub set
{
	my ($self, $p_state, $p_setby, $p_respond) = @_;
	my $link_state = &Insteon::BaseObject::derive_link_state($p_state);
	return $self->Insteon::BaseDevice::set($link_state, $p_setby, $p_respond);
}

sub request_status 
{
	my ($self, $requestor) = @_;
	if (!($self->is_root)) {
		my $parent = $self->get_root();
		$$parent{child_status_request_pending} = $self->group;
		$$self{m_status_request_pending} = ($requestor) ? $requestor : 1;
		my $message = new Insteon::InsteonMessage('insteon_send', $parent, 'status_request', '01');
		$parent->_send_cmd($message);
	} else {
		$self->SUPER::request_status($requestor);
	}
}

sub _is_info_request
{
	my ($self, $cmd, $ack_setby, %msg) = @_;
	my $is_info_request = 0;
	my $parent = $self->get_root();
	if ($$parent{child_status_request_pending}) {
		$is_info_request++;
		my $child_obj = Insteon::get_object($self->device_id, '02');
		my $child_state = &Insteon::BaseObject::derive_link_state(hex($msg{extra}));
		&::print_log("[Insteon::IOLinc] received status for " .
			$child_obj->{object_name} . " of: $child_state "
			. "hops left: $msg{hopsleft}") if $main::Debug{insteon};
		$ack_setby = $$child_obj{m_status_request_pending} if ref $$child_obj{m_status_request_pending};
		$child_obj->SUPER::set($child_state, $ack_setby);
		delete($$parent{child_status_request_pending});
	}
	else {
		$is_info_request = $self->SUPER::_is_info_request($cmd, $ack_setby, %msg);
	}
	return $is_info_request;
}

=item C<set_momentary_time(time)>

$time in (10th of seconds) is the length of time the relay will close when 
Momentary is selected.

Default 20

Changes must be written with C<write_settings()>

=cut

sub set_momentary_time 
{
	my ($self, $momentary_time) = @_;
	$$self{momentary_time} = $momentary_time if ($momentary_time && $self->is_root);
	return $$self{momentary_time};
}

=item C<set_relay_linked([0|1])>

If set to 1 sets Relay On when Sensor is On and Off when sensor if Off.

Default 0

Changes must be written with C<write_settings()>

=cut

sub set_relay_linked 
{
	my ($self, $relay_linked) = @_;
	$$self{relay_linked} = $relay_linked if ($relay_linked && $self->is_root);
	return $$self{relay_linked};
}

=item C<set_trigger_reverse([0|1])>

If set to 1, it reverses the sensor value so that a closed sensor switch sends an OFF
and open sensor switch sends an ON. 

Default 0

Changes must be written with C<write_settings()>

=cut

sub set_trigger_reverse 
{
	my ($self, $trigger_reverse) = @_;
	$$self{trigger_reverse} = $trigger_reverse if ($trigger_reverse && $self->is_root);
	return $$self{trigger_reverse};
}

=item C<set_relay_mode(mode)>

Sets the relay mode to [Latching|Momentary_A|Momentary_B|Momentary_C]

Latching: The relay will remain open or closed until another command is received. 
Momentary time is ignored.

Momentary_A: The relay will close momentarily. If it is Linked while On it will 
respond to On. If it is Linked while Off it will respond to Off.

Momentary_B: Both - On and Off both cause the relay to close momentarily.

Momentary_C: Look at Sensor - If the sensor is On the relay will close momentarily 
when an On command is received. If the sensor is Off the relay will close momentarily 
when an Off command is received.

Default Latching

Changes must be written with C<write_settings()>

=cut

sub set_relay_mode 
{
	my ($self, $relay_mode) = @_;
	$$self{relay_mode} = $relay_mode if ($relay_mode && $self->is_root);
	return $$self{relay_mode};
}

=item C<write_settings()>

Writes momentary_time, relay_linked, trigger_reverse and relay_mode settings to
the device.

=cut

sub write_settings
{
	my ($self) = @_;
	return;
}

1;
=back
=cut
