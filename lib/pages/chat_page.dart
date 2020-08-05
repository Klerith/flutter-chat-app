import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:chat/services/auth_service.dart';
import 'package:chat/services/chat_service.dart';
import 'package:chat/services/socket_service.dart';

import 'package:chat/models/mensajes_response.dart';
import 'package:chat/widgets/chat_message.dart';


class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {

  final _textController = new TextEditingController();
  final _focusNode = new FocusNode();
  
  ChatService chatService;
  SocketService socketService;
  AuthService authService;

  List<ChatMessage> _messages = [];


  bool _estaEscribiendo = false;

  @override
  void initState() { 
    super.initState();
    
    this.chatService   = Provider.of<ChatService>(context, listen: false);
    this.socketService = Provider.of<SocketService>(context, listen: false);
    this.authService   = Provider.of<AuthService>(context, listen: false);

    this.socketService.socket.on('mensaje-personal', _escucharMensaje );

    _cargarHistorial( this.chatService.usuarioPara.uid );
  } 

  void _cargarHistorial( String usuarioID ) async {

    List<Mensaje> chat = await this.chatService.getChat(usuarioID);

    final history = chat.map((m) => new ChatMessage(
      texto: m.mensaje,
      uid: m.de,
      animationController: new AnimationController(vsync: this, duration: Duration( milliseconds: 0))..forward(),
    ));

    setState(() {
      _messages.insertAll(0, history);
    });

  }

  void _escucharMensaje( dynamic payload ) {
    
    ChatMessage message = new ChatMessage(
      texto: payload['mensaje'],
      uid: payload['de'],
      animationController: AnimationController( vsync: this, duration: Duration(milliseconds: 300 )),
    );

    setState(() {
      _messages.insert(0, message);
    });

    message.animationController.forward();

  }


  @override
  Widget build(BuildContext context) {

    final usuarioPara = chatService.usuarioPara;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Column(
          children: <Widget>[
            CircleAvatar(
              child: Text( usuarioPara.nombre.substring(0,2) , style: TextStyle(fontSize: 12) ),
              backgroundColor: Colors.blue[100],
              maxRadius: 14,
            ),
            SizedBox( height: 3 ),
            Text( usuarioPara.nombre  , style: TextStyle( color: Colors.black87, fontSize: 12))
          ],
        ),
        centerTitle: true,
        elevation: 1,
      ),

      body: Container(
        child: Column(
          children: <Widget>[
            
            Flexible(
              child: ListView.builder(
                physics: BouncingScrollPhysics(),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _messages[i],
                reverse: true,
              )
            ),

            Divider( height: 1 ),

            // TODO: Caja de texto
            Container(
              color: Colors.white,
              child: _inputChat(),
            )
          ],
        ),
      ),
   );
  }

  Widget _inputChat() {

    return SafeArea(
      child: Container(
        margin: EdgeInsets.symmetric( horizontal: 8.0 ),
        child: Row(
          children: <Widget>[

            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmit ,
                onChanged: ( texto ){
                  setState(() {
                    if ( texto.trim().length > 0 ) {
                      _estaEscribiendo = true;
                    } else {
                      _estaEscribiendo = false;
                    }
                  });
                },
                decoration: InputDecoration.collapsed(
                  hintText: 'Enviar mensaje'
                ),
                focusNode: _focusNode,
              )
            ),

            // Botón de enviar
            Container(
              margin: EdgeInsets.symmetric( horizontal: 4.0 ),
              child: Platform.isIOS 
              ? CupertinoButton(
                child: Text('Enviar'), 
                onPressed: _estaEscribiendo 
                  ? () => _handleSubmit( _textController.text.trim() )
                  : null,
              )
              
              : Container(
                margin: EdgeInsets.symmetric( horizontal: 4.0 ),
                child: IconTheme(
                  data: IconThemeData( color: Colors.blue[400] ),
                  child: IconButton(
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    icon: Icon( Icons.send ),
                    onPressed: _estaEscribiendo 
                      ? () => _handleSubmit( _textController.text.trim() )
                      : null,
                  ),
                ),
              ),
            )

          ],
        ),
      )
    );

  }


  _handleSubmit(String texto ) {

    if ( texto.length == 0 ) return;

    _textController.clear();
    _focusNode.requestFocus();

    final newMessage = new ChatMessage(
      uid: authService.usuario.uid, 
      texto: texto,
      animationController: AnimationController(vsync: this, duration: Duration( milliseconds: 200 )),
    );
    _messages.insert(0, newMessage);
    newMessage.animationController.forward();

    setState(() { _estaEscribiendo = false; });

    this.socketService.emit('mensaje-personal', {
      'de': this.authService.usuario.uid,
      'para': this.chatService.usuarioPara.uid,
      'mensaje': texto
    });
  }

  @override
  void dispose() {
    for( ChatMessage message in _messages ) {
      message.animationController.dispose();
    }

    this.socketService.socket.off('mensaje-personal');
    super.dispose();
  }

}