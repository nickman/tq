package tqueue.obridge.objects;

import java.sql.Timestamp;
import java.sql.Date;
import java.util.List;
import java.math.BigDecimal;
import javax.annotation.Generated;

@Generated("org.obridge.generators.EntityObjectGenerator")
public class Fullorder {

    private BigDecimal orderId;
    private Date orderDate;
    private List<Orderitem> items;

    public BigDecimal getOrderId() {
        return this.orderId;
    }

    public void setOrderId(BigDecimal orderId) {
        this.orderId = orderId;
    }

    public Date getOrderDate() {
        return this.orderDate;
    }

    public void setOrderDate(Date orderDate) {
        this.orderDate = orderDate;
    }

    public List<Orderitem> getItems() {
        return this.items;
    }

    public void setItems(List<Orderitem> items) {
        this.items = items;
    }


}
