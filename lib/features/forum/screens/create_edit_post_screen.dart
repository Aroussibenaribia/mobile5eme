import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../services/auth_service.dart';
import '../models/forum_post_model.dart';
import '../models/forum_category_model.dart';
import '../providers/forum_provider.dart';
import '../utils/forum_validators.dart';

class CreateEditPostScreen extends StatefulWidget {
  final ForumPostModel? postToEdit;

  const CreateEditPostScreen({super.key, this.postToEdit});

  @override
  State<CreateEditPostScreen> createState() => _CreateEditPostScreenState();
}

class _CreateEditPostScreenState extends State<CreateEditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String? _selectedCategory;
  String? _imagePath;
  bool _isResolved = false;
  bool _isLoading = false;
  bool _hasModified = false;
  bool _submitted = false; // tracks first submit attempt for autovalidateMode

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.postToEdit?.title ?? '');
    _contentController =
        TextEditingController(text: widget.postToEdit?.content ?? '');
    _selectedCategory = widget.postToEdit?.category ?? 'Plomberie';
    _imagePath = widget.postToEdit?.imageUrl;
    _isResolved = widget.postToEdit?.isResolved ?? false;

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    // Rebuilds on every keystroke so counters update live AND marks modified
    setState(() {
      _hasModified = true;
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _contentController.removeListener(_onTextChanged);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() {
          _imagePath = picked.path;
          _hasModified = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de sélectionner l\'image: $e')),
        );
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ajouter une photo du diagnostic',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.primary),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: AppColors.primary),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final categoryError = ForumValidators.validateCategory(_selectedCategory);
    if (categoryError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(categoryError), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    final currentUserId = user?.id ?? 'guest_user';
    final currentUserName = user?.fullName ?? 'Utilisateur HomeFix';
    final currentUserAvatar = user?.avatarUrl;
    final currentUserRole = user?.isProfessional == true ? 'Artisan' : 'Client';

    final forumProvider = context.read<ForumProvider>();
    String? error;

    if (widget.postToEdit != null) {
      // Edit mode
      final updated = widget.postToEdit!.copyWith(
        title: _titleController.text,
        content: _contentController.text,
        category: _selectedCategory!,
        imageUrl: _imagePath,
        isResolved: _isResolved,
      );
      error = await forumProvider.updatePost(updated);
    } else {
      // Create mode
      error = await forumProvider.createPost(
        authorId: currentUserId,
        authorName: currentUserName,
        authorAvatar: currentUserAvatar,
        authorRole: currentUserRole,
        title: _titleController.text,
        content: _contentController.text,
        category: _selectedCategory!,
        imageUrl: _imagePath,
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.warning),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.postToEdit != null
              ? 'Modifications enregistrées !'
              : 'Question publiée avec succès !'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.postToEdit != null;

    return PopScope(
      canPop: !_hasModified,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Abandonner la saisie ?'),
            content:
                const Text('Vos modifications ne seront pas enregistrées.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Continuer la saisie'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Abandonner',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (shouldLeave == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(isEditing ? 'Modifier la question' : 'Nouvelle question'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Picker Dropdown
                const Text(
                  'Corps de métier concerné *',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedCategory,
                      icon: const Icon(Icons.arrow_drop_down_rounded,
                          color: AppColors.primary),
                      items: ForumCategoryModel.categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat.name,
                          child: Row(
                            children: [
                              Icon(cat.icon, size: 18, color: cat.color),
                              const SizedBox(width: 10),
                              Text(cat.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val;
                          _hasModified = true;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Title Input with Live Counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Titre de votre question *',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary),
                    ),
                    Text(
                      '${_titleController.text.length} / 90',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _titleController.text.length > 80
                            ? AppColors.warning
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  validator: ForumValidators.validateTitle,
                  maxLength: 90,
                  buildCounter: (_,
                          {required currentLength,
                          required isFocused,
                          maxLength}) =>
                      const SizedBox.shrink(),
                  style: const TextStyle(
                      fontSize: 14.5, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText:
                        'Ex: Fuite d\'eau sous évier, panne disjoncteur...',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Description Input with Live Counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Description détaillée du problème *',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary),
                    ),
                    Text(
                      '${_contentController.text.length} / 2000',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _contentController.text.length > 1800
                            ? AppColors.warning
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contentController,
                  validator: ForumValidators.validateContent,
                  maxLines: 6,
                  maxLength: 2000,
                  buildCounter: (_,
                          {required currentLength,
                          required isFocused,
                          maxLength}) =>
                      const SizedBox.shrink(),
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textPrimary, height: 1.45),
                  decoration: InputDecoration(
                    hintText:
                        'Expliquez ce qui s\'est passé, les symptômes constatés, les démarches déjà essayées...',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Diagnostic Photo Attachment (Métier 5)
                const Text(
                  'Photo du problème (Optionnel mais recommandé)',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                if (_imagePath != null && _imagePath!.isNotEmpty)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: !kIsWeb && File(_imagePath!).existsSync()
                            ? Image.file(
                                File(_imagePath!),
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 120,
                                color: AppColors.primaryLight,
                                alignment: Alignment.center,
                                child: Text('Image jointe : $_imagePath'),
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: () => setState(() => _imagePath = null),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  InkWell(
                    onTap: _showImageSourcePicker,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.cardBorder,
                            style: BorderStyle.solid),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: AppColors.primary, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Ajouter une photo (caméra ou galerie)',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (isEditing) ...[
                  const SizedBox(height: 18),
                  SwitchListTile(
                    value: _isResolved,
                    onChanged: (val) => setState(() => _isResolved = val),
                    title: const Text('Marquer ce sujet comme résolu',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text(
                        'Indique aux artisans que votre problème a trouvé une solution.',
                        style: TextStyle(fontSize: 12)),
                    activeTrackColor: AppColors.success,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],

                const SizedBox(height: 30),

                // Submit Button
                CustomButton(
                  text: isEditing
                      ? 'Enregistrer les modifications'
                      : 'Publier ma question',
                  icon: isEditing ? Icons.save_rounded : Icons.send_rounded,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _submitForm,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
