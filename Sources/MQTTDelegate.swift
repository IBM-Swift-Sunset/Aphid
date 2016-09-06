/**
 Copyright IBM Corporation 2016

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation


public protocol MQTTDelegate {
    
    func didConnect()
    /**
     This method is called when the connection to the server is lost.

     throws: cause of the reason behind the loss of connection.
     */
    func didLoseConnection(error: Error?)

    /**
     Called when delivery for a message has been completed, and all
     acknowledgements have been received. For QoS messages it is
     called once the message has been handed to the network for
     delivery. For QoS 1 it is called when PUBACK is received and
     for QoS 2 when PUBCOMP is received. The token will be the same
     token as that returned when the message was published.

     - parameter token: token the delivery token associated with the message
     */
    func didCompleteDelivery(token: String)



    /**
     This method is called when a message arrives from the server.

     This method is invoked synchronously by the MQTT client. An
     acknowledgment is not sent back to the server until this
     method returns cleanly.

     If an implementation of this method throws an <code>Exception</code>, then the
     client will be shut down.  When the client is next re-connected, any QoS
     1 or 2 messages will be redelivered by the server.

     Any additional messages which arrive while an
     implementation of this method is running, will build up in memory, and
     will then back up on the network.

     If an application needs to persist data, then it
     should ensure the data is persisted prior to returning from this method, as
     after returning from this method, the message is considered to have been
     delivered, and will not be reproducible.

     It is possible to send a new message within an implementation of this callback
     (for example, a response to this message), but the implementation must not
     disconnect the client, as it will be impossible to send an acknowledgment for
     the message being processed, and a deadlock will occur.

     - parameter topic: name of the topic on the message was published to
     - parameter message: the actual message
     - throws: exception if an error has occurred, and the client should be shut down.
     */
    func didReceiveMessage(topic: String, message: String)



}
