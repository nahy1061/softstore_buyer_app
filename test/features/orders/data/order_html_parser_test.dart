import 'package:flutter_test/flutter_test.dart';
import 'package:softstore_buyer_app/features/orders/data/order_html_parser.dart';
import 'package:softstore_buyer_app/features/orders/models/order_model.dart';

void main() {
  group('OrderHtmlParser', () {
    test('parseOrdersList parses order cards from HTML', () {
      const sampleHtml = '''
      <div class="orders-list">
        <div class="order-card" data-invoice="INV-20260812-12345">
          <a href="/store/account/orders/INV-20260812-12345" data-invoice="INV-20260812-12345">Invoice #INV-20260812-12345</a>
          <span class="status-badge badge-success">Confirmed</span>
          <span class="order-date">2026-08-12</span>
          <span class="order-total">PKR 2,750</span>
          <span class="store-name">Alpha Store</span>
          <span class="item-count">2 items</span>
        </div>
      </div>
      ''';

      final orders = OrderHtmlParser.parseOrdersList(sampleHtml);
      expect(orders.length, 1);
      final order = orders.first;
      expect(order.referenceNumber, 'INV-20260812-12345');
      expect(order.status, OrderStatus.confirmed);
      expect(order.subtotal, 2750.0);
      expect(order.storeName, 'Alpha Store');
    });

    test('parseOrderDetail parses order detail HTML', () {
      const sampleDetailHtml = '''
      <div class="order-detail-container">
        <h2 class="invoice-number">Invoice #INV-20260812-12345</h2>
        <span class="status-badge">Delivered</span>
        <span class="order-date">2026-08-12</span>
        <div class="shipping-address">
          John Doe
          +92-300-1234567
          123 Street 4, Blue Area
          Islamabad
        </div>
        <div class="store-info">
          <strong class="store-name">Tech Store Direct</strong>
        </div>
        <table class="order-items">
          <tbody>
            <tr class="order-item">
              <td class="product-name">Wireless Keyboard</td>
              <td class="item-qty">2</td>
              <td class="item-price">PKR 1,500</td>
            </tr>
          </tbody>
        </table>
        <div class="subtotal">PKR 3,000</div>
        <div class="delivery-fee">PKR 200</div>
        <div class="discount">PKR 100</div>
      </div>
      ''';

      final order = OrderHtmlParser.parseOrderDetail(sampleDetailHtml, defaultReferenceNumber: 'INV-20260812-12345');
      expect(order.referenceNumber, 'INV-20260812-12345');
      expect(order.status, OrderStatus.delivered);
      expect(order.items.length, 1);
      expect(order.items.first.name, 'Wireless Keyboard');
      expect(order.items.first.quantity, 2);
      expect(order.items.first.unitPrice, 1500.0);
      expect(order.subtotal, 3000.0);
      expect(order.deliveryFee, 200.0);
      expect(order.discount, 100.0);
      expect(order.total, 3100.0);
    });
  });
}
