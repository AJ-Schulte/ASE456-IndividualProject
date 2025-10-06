import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  final db = Db(
    'mongodb://tempuser:12341234@'
    'ac-ukfjcfj-shard-00-00.yawcomh.mongodb.net:27017,'
    'ac-ukfjcfj-shard-00-01.yawcomh.mongodb.net:27017,'
    'ac-ukfjcfj-shard-00-02.yawcomh.mongodb.net:27017/deck-builder'
    '?ssl=true&replicaSet=atlas-ouaup3-shard-0&authSource=admin&retryWrites=true&w=majority',
  );
  await db.open();


  final deckCollection = db.collection('decks');
  final userCollection = db.collection('users');

  final router = Router();

  // Get all decks
  router.get('/decks', (Request req) async {
    final decks = await deckCollection.find().toList();
    return Response.ok(jsonEncode(decks), headers: {'Content-Type': 'application/json'});
  });

  // Get public decks
  router.get('/decks/public', (Request req) async {
    final publicDecks = await deckCollection.find(where.eq('public', true)).toList();
    return Response.ok(jsonEncode(publicDecks), headers: {'Content-Type': 'application/json'});
  });

  // Get decks for a user
  router.get('/decks/user/<username>', (Request req, String username) async {
    final userDecks = await deckCollection.find(where.eq('username', username)).toList();
    return Response.ok(jsonEncode(userDecks), headers: {'Content-Type': 'application/json'});
  });

  // Add a deck
  router.post('/decks', (Request req) async {
    final body = await req.readAsString();
    await deckCollection.insertOne(body as Map<String, dynamic>);
    return Response.ok('{"status":"ok"}', headers: {'Content-Type': 'application/json'});
  });

  router.put('/decks/<username>/<deckname>', (Request req, String username, String deckname) async {
    final body = await req.readAsString();
    final updateFields = jsonDecode(body) as Map<String, dynamic>;

    final result = await deckCollection.updateOne(
      where.eq('username', username).eq('deckname', deckname),
      {
        r'$set': updateFields,
      },
    );

    return Response.ok(
      jsonEncode({
        'message': 'Deck updated',
        'modifiedCount': result.nModified,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.delete('/decks/<username>/<deckname>', (Request req, String username, String deckname) async {
    final result = await deckCollection.deleteOne(
      where.eq('username', username).eq('deckname', deckname),
    );

    return Response.ok(
      jsonEncode({
        'message': 'Deck deleted',
        'deletedCount': result.nRemoved,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  });


  router.post('/signup', (Request req) async {
    final body = await req.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final username = data['username'];
    final password = data['password'];
    final email = data['email'];

    if (username == null || password == null || email == null) {
      return Response(400, body: '{"error":"Missing username, password, or email"}');
    }

    final existing = await userCollection.findOne(where.eq('username', username));
    if (existing != null) {
      return Response(400, body: '{"error":"User already exists"}');
    }
    final emailExists = await userCollection.findOne(where.eq('email', email));
    if (emailExists != null) {
      return Response(400, body: '{"error":"Email already exists"}');
    }

    await userCollection.insertOne({
      'username': username,
      'password': password,
      'email': email,
    });

    return Response.ok(
      jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // Update user
  router.put('/users/<username>', (Request req, String username) async {
    final body = await req.readAsString();
    final newInfo = jsonDecode(body) as Map<String, dynamic>;

    if (newInfo.isEmpty) {
      return Response(
        400,
        body: '{"error":"No fields to update"}',
        headers: {'Content-Type': 'application/json'},
      );
    }

    final existingUser = await userCollection.findOne(where.eq('username', username));
    if (existingUser == null) {
      return Response(
        404,
        body: '{"error":"User not found"}',
        headers: {'Content-Type': 'application/json'},
      );
    }

    existingUser.addAll(newInfo);
    existingUser.remove('_id'); 

    final result = await userCollection.update(
      where.eq('username', username),
      existingUser,
      upsert: false,
      multiUpdate: false,
    );

    if (result['n'] == 0) {
      return Response(
        500,
        body: '{"error":"Failed to update user"}',
        headers: {'Content-Type': 'application/json'},
      );
    }

    final updatedUser = await userCollection.findOne(where.eq(
      'username',
      existingUser['username'],
    ));

    return Response.ok(
      jsonEncode({
        'username': updatedUser?['username'],
        'password': updatedUser?['password'],
        'email': updatedUser?['email'],
      }),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // Login
  router.post('/login', (Request req) async {
    final body = await req.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final username = data['username'];
    final password = data['password'];

    if (username == null || password == null) {
      return Response(400, body: '{"error":"Missing username or password"}');
    }

    final user = await userCollection.findOne(where.eq('username', username));
    if (user == null || user['password'] != password) {
      return Response(401, body: '{"error":"Invalid username or password"}');
    }

    return Response.ok(
      jsonEncode({
        'username': user['username'],
        'email': user['email'],
        'password': user['password'],
      }),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // Get a user
  router.get('/users/<username>', (Request req, String username) async {
    final user = await userCollection.find(where.eq('username', username)).toList();
    return Response.ok(jsonEncode(user), headers: {'Content-Type': 'application/json'});
  });

  Middleware handleCORS() {
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
    };

    Response? optionsHandler(Request request) {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: corsHeaders);
      }
      return null;
    }

    return (Handler handler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return optionsHandler(request)!;
        }
        final response = await handler(request);
        return response.change(headers: corsHeaders);
      };
    };
  }

  // Start server
  final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(handleCORS()) 
        .addHandler(router);
  final server = await serve(handler, InternetAddress.loopbackIPv4, 8080);
  print('✅ Server running at http://${server.address.host}:${server.port}');
}

