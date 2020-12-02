import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'person.dart';
import 'person_list_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Persons',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ChangeNotifierProvider(
        create: (ctx) => EntityListProvider(),
        child: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentTabIndex = 0;

  final List<Widget> _telas = [
    const _HomeTab(),
    const _ListTab(),
    const _FormTab()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Persons'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: _onTabTapped,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.format_list_bulleted),
            label: 'Listar',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.my_library_add_outlined),
            label: 'Cadastrar',
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: _telas[_currentTabIndex],
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() => _currentTabIndex = index);
  }
}

enum _Result {
  SUCCESS,
  ERROR,
  CANCELED,
}

/// Widget responsável pela tab inicial
class _HomeTab extends StatelessWidget {
  const _HomeTab();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'Bem vindo!',
            style: TextStyle(
              fontSize: 48,
            ),
          ),
          Divider(),
          RaisedButton(
            color: Colors.blue,
            textColor: Colors.white,
            child: Text('Sincronizar'),
            onPressed: () async {
              final confirma = await showConfirmDialog(
                context,
                'A sincronização irá apagar os dados locais e sobreescrever com os do WebService. Deseja prosseguir?',
              );
              // Se não confirmou, encerra o fluxo
              if (!confirma) {
                return;
              }

              // Apaga o Snackbar (se aplicável) antes de sincronizar
              final scaffold = ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar();

              // Configura as futures e o interruptor (cancelamento)
              final _interruptor = Completer();
              final synchronization = Future.any([
                _makeSynchronization(context),
                _interruptor.future,
              ]);

              // Função executada após a sincronização
              synchronization.then((value) {
                var text;
                if (value == _Result.SUCCESS) {
                  text = const Text('Sincronização finalizada com sucesso!');
                } else if (value == _Result.ERROR) {
                  text = const Text(
                    'Sincronização finalizada com erro! Tente novamente mais tarde',
                  );
                } else {
                  text = const Text('Cancelado pelo usuário!');
                }
                scaffold.showSnackBar(SnackBar(content: text));
                // Após a sincronização, exibe uma mensagem
                if (value != null) {
                  Navigator.of(context).pop();
                }
              });

              // Exibe o loading
              showModalBottomSheet(
                context: context,
                builder: (context) => _SynchronizationScreen(onCancel: () {
                  _interruptor.complete(_Result.CANCELED);
                }),
              ).then((value) {
                if (!_interruptor.isCompleted) _interruptor.complete();
              });
            },
          )
        ],
      ),
    );
  }

  Future<_Result> _makeSynchronization(BuildContext context) async {
    try {
      final provider = Provider.of<EntityListProvider>(context, listen: false);
      await provider.removeAllFromDatabase();
      List<Person> pessoas = await provider.getFromWebService();
      for (Person p in pessoas) {
        await provider.saveOnDatabase(p);
      }
      return _Result.SUCCESS;
    } catch (e) {
      print(e);
      return _Result.ERROR;
    }
  }
}

/// Widget responsável pela tab de listagem
class _ListTab extends StatelessWidget {
  const _ListTab();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FittedBox(child: Text('Listagem de pessoas')),
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: _loadListFuture(context),
              builder: (context, snapshot) => snapshot.connectionState ==
                      ConnectionState.waiting
                  ? Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => _loadListFuture(context),
                      child: Consumer<EntityListProvider>(
                          builder: (context, provider, child) {
                        return ListView.builder(
                            itemCount: provider.count,
                            itemBuilder: (ctx, index) {
                              final entidade = provider.getByIndex(index);
                              return Dismissible(
                                key: Key(entidade.hashCode.toString()),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (direction) async {
                                  return await showConfirmDialog(context,
                                      'Deseja realmente excluir o registro ${entidade.name} (${entidade.id})?');
                                },
                                onDismissed: (direction) {
                                  provider.removeOneFromDatabase(entidade);
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: 80,
                                  child: Card(
                                    child: ListTile(
                                      title: Text(entidade.name),
                                      subtitle: Text(entidade.address1),
                                      trailing: Text(entidade.address2),
                                      leading: CircleAvatar(
                                        radius: 30,
                                        backgroundImage: entidade.photo != null
                                            ? NetworkImage(entidade.photo)
                                            : NetworkImage(
                                                'https://randomuser.me/api/portraits/men/99.jpg'),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            });
                      }),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadListFuture(BuildContext context) =>
      Provider.of<EntityListProvider>(context, listen: false).loadList();
}

/// Widget responsável pela tela de sincronização
class _SynchronizationScreen extends StatelessWidget {
  const _SynchronizationScreen({
    Key key,
    this.onCancel,
  }) : super(key: key);

  final void Function() onCancel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Sincronizando...', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
            const SizedBox(height: 40),
            RaisedButton(
              color: Colors.red,
              textColor: Colors.white,
              child: Text('Cancelar'),
              onPressed: onCancel,
            )
          ],
        ),
      ),
    );
  }
}

/// Widget responsável pela tab de formulário
class _FormTab extends StatefulWidget {
  const _FormTab();

  @override
  __FormTabState createState() => __FormTabState();
}

class __FormTabState extends State<_FormTab> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _adress1Ctrl = TextEditingController();
  final _adress2Ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) => Form(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                SizedBox(
                  height: 120,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FittedBox(child: Text('Cadastro de pessoas')),
                  ),
                ),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: 'Nome'),
                        controller: _nameCtrl,
                        validator: (value) => textMinSize(value, size: 3),
                      ),
                      TextFormField(
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: 'E-mail'),
                        controller: _emailCtrl,
                      ),
                      TextFormField(
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: 'Phone'),
                        controller: _phoneCtrl,
                      ),
                      TextFormField(
                        textInputAction: TextInputAction.next,
                        decoration:
                            InputDecoration(labelText: 'Endereço linha 1'),
                        controller: _adress1Ctrl,
                        validator: (value) => textNotEmpty(value),
                      ),
                      TextFormField(
                        textInputAction: TextInputAction.next,
                        decoration:
                            InputDecoration(labelText: 'Endereço linha 2'),
                        controller: _adress2Ctrl,
                        validator: (value) => textNotEmpty(value),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          FlatButton(
                              child: Text('Cancelar'), onPressed: _onCancel),
                          RaisedButton(
                              color: Colors.blue,
                              textColor: Colors.white,
                              child: Text('Gravar'),
                              onPressed: _onSubmit),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      );

  void _onCancel() async {
    final currentState = _formKey.currentState;
    final confirma = await showConfirmDialog(
      context,
      'Deseja limpar o formulário?',
    );
    if (confirma) {
      currentState.reset();
    }
  }

  void _onSubmit() async {
    if (!_formKey.currentState.validate()) {
      return;
    }
    final String name = _nameCtrl.text.trim();
    final String email = _emailCtrl.text.trim();
    final String phone = _phoneCtrl.text.trim();
    final String address1 = _adress1Ctrl.text.trim();
    final String address2 = _adress2Ctrl.text.trim();

    final completer = showLoadingDialog(context);

    try {
      final provider = Provider.of<EntityListProvider>(context, listen: false);
      await provider.gravar(Person(
        name: name,
        email: email,
        phone: phone,
        address1: address1,
        address2: address2,
      ));
    } finally {
      completer.complete();
    }
    // Limpa o formulário e informa que gravou com sucesso
    _formKey.currentState.reset();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Registro gravado com sucesso!')));
  }
}

Completer showLoadingDialog(BuildContext context,
    {String message = 'Aguarde...'}) {
  final completer = Completer()
    ..future.then((_) {
      Navigator.of(context).pop();
    });
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => WillPopScope(
      onWillPop: () async => false,
      child: SimpleDialog(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(message, style: TextStyle(fontSize: 24)),
              const SizedBox(height: 40),
              const CircularProgressIndicator(),
            ],
          )
        ],
      ),
    ),
  );
  return completer;
}

Future<bool> showConfirmDialog(BuildContext context, String message,
    {String title = 'Confirma?'}) async {
  final result = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        FlatButton(
            child: Text('Não'),
            onPressed: () {
              Navigator.of(context).pop(false);
            }),
        RaisedButton(
            color: Colors.blue,
            textColor: Colors.white,
            child: Text('Sim'),
            onPressed: () {
              Navigator.of(context).pop(true);
            })
      ],
    ),
  );
  return result == true;
}

///
/// Texto obrigatório
///
String textNotEmpty(String value, {message = 'O campo é obrigatório'}) {
  return value.isEmpty ? message : null;
}

///
/// Texto com tamanho mínimo
///
String textMinSize(String value, {size: 5, message}) {
  message ??= 'Informe pelo menos $size carácteres';
  return textNotEmpty(
        value,
        message: message,
      ) ??
      (value.length < size ? message : null);
}
