import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decimal/decimal.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

class ImportItem extends StatefulWidget {
  const ImportItem({super.key});

  @override
  State<ImportItem> createState() => _ImportItemState();
}

class _ImportItemState extends State<ImportItem> {
  bool _isLoading = false;
  String _statusMessage = '';
  bool _hasError = false;
  int _successCount = 0;
  int _errorCount = 0;
  final _firestore = FirebaseFirestore.instance;

  Future<void> _importData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Selecting Excel file.....';
      _hasError = false;
      _successCount = 0;
      _errorCount = 0;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'No file selected';
        });
        return;
      }

      Uint8List bytes;
      final file = result.files.single;

      if (file.bytes != null) {
        bytes = file.bytes!;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Failed to read file content';
          _hasError = true;
        });
        return;
      }

      final decoder = SpreadsheetDecoder.decodeBytes(bytes, update: false);
      final table = decoder.tables.values.first;

      if (table.rows.isEmpty) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'No data found in Excel sheet';
          _hasError = true;
        });
        return;
      }

      final batch = _firestore.batch();
      final collectionRef = _firestore.collection('item_master_data');

      for (int i = 1; i < table.rows.length; i++) {
        try {
          final row = table.rows[i];
          if (row.length < 4) {
            _errorCount++;
            continue;
          }

          final itemCode = _parseInt(row[0]);
          if (itemCode == null || itemCode <= 0) {
            _errorCount++;
            continue;
          }

          final itemName = _parseString(row[1]);
          final itemAmount = Decimal.parse(_parseDouble(row[2]).toString());
          final itemStatus = _parseBool(row[3]);
          Timestamp timestamp;

          if (row.length > 4 && row[4] != null) {
            try {
              final dateStr = row[4].toString();
              timestamp = Timestamp.fromDate(
                DateFormat('dd/MM/yyyy').parse(dateStr),
              );
            } catch (_) {
              timestamp = Timestamp.now();
            }
          } else {
            timestamp = Timestamp.now();
          }

          final item = ItemMasterData(
            itemCode: itemCode,
            itemName: itemName,
            itemAmount: itemAmount.toDouble(),
            itemStatus: itemStatus ?? false,
            timestamp: timestamp,
          );

          batch.set(collectionRef.doc(), item.toFirestore());
          _successCount++;

          if (i % 10 == 0) {
            setState(() {
              _statusMessage = 'Processing row $i/${table.rows.length - 1}...';
            });
            await Future.delayed(const Duration(milliseconds: 1));
          }
        } catch (e) {
          debugPrint('Error processing row $i: $e');
          _errorCount++;
        }
      }

      setState(() {
        _statusMessage = 'Uploading item data to Firestore....';
      });

      await batch.commit();

      setState(() {
        _isLoading = false;
        _statusMessage =
            'Import completed!\n'
            'Success: $_successCount\n'
            'Errors: $_errorCount';
        _hasError = _errorCount > 0;
      });
    } catch (e) {
      debugPrint('Import error: $e');
      setState(() {
        _isLoading = false;
        _statusMessage = 'Import failed: ${e.toString()}';
        _hasError = true;
      });
    }
  }

  String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString().trim());
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString().trim()) ?? 0.0;
  }

  bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final strValue = value.toString().trim().toLowerCase();

    if (strValue == 'true' ||
        strValue == '1' ||
        strValue == 'yes' ||
        strValue == 'y') {
      return true;
    }

    if (strValue == 'false' ||
        strValue == '0' ||
        strValue == 'no' ||
        strValue == 'n') {
      return false;
    }
    return null; // Return null if parsing fails
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Item Master Data')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Import Item Master Datas from Excel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Expected column order: \n'
              '1. Item Code\n'
              '2. Item Name\n'
              '3. Item Amount\n'
              '4. Item Status\n',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _importData,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Select Excel File on Import'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _hasError ? Colors.red[100] : Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  color: _hasError ? Colors.red[800] : Colors.green[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ItemMasterData {
  final int itemCode;
  final String itemName;
  final double itemAmount;
  final bool itemStatus;
  final Timestamp timestamp;

  ItemMasterData({
    required this.itemCode,
    required this.itemName,
    required this.itemAmount,
    required this.itemStatus,
    required this.timestamp,
  });

  // convert a itemmasterdata object into a map object for firebase
  Map<String, dynamic> toFirestore() {
    return {
      'item_code': itemCode,
      'item_name': itemName,
      'item_amount': itemAmount,
      'item_status': itemStatus,
      'timestamp': timestamp,
    };
  }
}
