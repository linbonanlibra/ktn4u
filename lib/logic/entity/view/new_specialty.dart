import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ktn4u/logic/entity/core/specialty.dart';
import 'package:ktn4u/logic/entity/view/specialty_book.dart';
import '../storage/litedb.dart';

class NewSpecialtyPage extends StatefulWidget {
  @override
  _NewSpecialtyPageState createState() => _NewSpecialtyPageState();
}

class _NewSpecialtyPageState extends State<NewSpecialtyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<XFile> _images = [];
  String? _selectedCategory;

  Map<String, int> cateNameToId = { for (var e in DishCategoryManager.getAllCategories()) e.name : e.id };
  final List<String> _categories = DishCategoryManager.getAllCategories()
      .map((category) => category.name)
      .toList(); // 示例分类

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _images.add(pickedFile);
      });
    }
  }

  Future<void> _saveDish() async {
    if (_formKey.currentState!.validate()) {
      final dish = DishDO(
        name: _nameController.text,
        description: _descriptionController.text,
        categoryId: cateNameToId[_selectedCategory!] ?? 0,
        images: _images.map((file) => file.path).toList(),
      );

      final storage = Storage();
      await storage.saveDish(dish);
    }
  }

  Future<void> _showConfirmationDialog(
      String title, String content, VoidCallback onConfirm) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(content),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确定'),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Specialty'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: '菜品名称'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入菜品名称';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(labelText: '选择分类'),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return '请选择分类';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: '菜品说明'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入菜品说明';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _images.map((file) {
                  return Stack(
                    children: [
                      Image.file(File(file.path),
                          width: 100, height: 100, fit: BoxFit.cover),
                      Positioned(
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _images.remove(file);
                            });
                          },
                          child: Icon(Icons.remove_circle, color: Colors.red),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera),
                    label: Text('拍照'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.photo_library),
                    label: Text('上传图片'),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  _showConfirmationDialog('发布确认', '确定要发布这个菜品吗？', () async {
                    await _saveDish();
                    Navigator.of(context).pop(true);
                  });
                },
                child: Text('发布'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  _showConfirmationDialog('取消确认', '确定要取消发布吗？', () {
                    Navigator.pop(context);
                  });
                },
                child: Text('取消'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
