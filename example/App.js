/**
 * Sample React Native App
 *
 * adapted from App.js generated by the following command:
 *
 * react-native init example
 *
 * https://github.com/facebook/react-native
 */

import React, { Component } from 'react';
import { StyleSheet, Text, View, NativeEventEmitter, NativeModules } from 'react-native';
import ContactTracing from 'react-native-contact-tracing';

export default class App extends Component<{}> {

  state = { status: '--', message: '--' };
  
  componentDidMount() {
    const eventEmitter = new NativeEventEmitter( NativeModules.ContactTracing );
    this.advertiseListener = eventEmitter.addListener('Advertise', e => console.log( 'ADVERTISED :', e ) );
    this.discoveryListener = eventEmitter.addListener('Discovery', e => console.log( 'DISCOVERED :', e ) );
    ContactTracing.isEnabled()
      .then( enabled => {
        this.setState( { status : enabled ? 'Enabled' : 'Disabled', message : 'Attempting startup...' } );
        ContactTracing.start()
          .then( _ => this.setState( { status : 'Enabled', message : 'See discovery logs in console' } ) )
          .catch( e => this.setState( { status : 'Startup Error', message : e } ) )
      } ).catch( e => this.setState( { status : 'Checking Error', message : e } ) );
  }

  componentWillUnmount() {
    this.advertiseListener.remove(); 
    this.discoveryListener.remove(); 
    ContactTracing.stop()
      .then( _ => this.setState( { status : 'Disabled', message : 'Exiting...' } ) )
      .catch( e => this.setState( { status : 'Stopping Error', message : e } ) );
  }

  render() {
    return (
      <View style={ styles.container }>
        <Text style={ styles.welcome }> ☆ContactTracing☆ </Text>
        <Text style={ styles.instructions }> STATUS : { this.state.status } </Text>
        <Text style={ styles.instructions }> { this.state.message } </Text>
      </View>
    );
  }

}

const styles = StyleSheet.create( {
  container: { flex : 1, justifyContent : 'center', alignItems : 'center', backgroundColor : '#F5FCFF' },
  welcome: { fontSize : 20, textAlign : 'center', margin : 10 },
  instructions: { textAlign : 'center', color : '#333333', marginBottom : 5 },
} );
