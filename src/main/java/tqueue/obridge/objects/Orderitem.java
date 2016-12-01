package tqueue.obridge.objects;

import java.sql.Timestamp;
import java.sql.Date;
import java.util.List;
import java.math.BigDecimal;
import javax.annotation.Generated;

@Generated("org.obridge.generators.EntityObjectGenerator")
public class Orderitem {

    private BigDecimal orderitemId;
    private String itemName;

    public BigDecimal getOrderitemId() {
        return this.orderitemId;
    }

    public void setOrderitemId(BigDecimal orderitemId) {
        this.orderitemId = orderitemId;
    }

    public String getItemName() {
        return this.itemName;
    }

    public void setItemName(String itemName) {
        this.itemName = itemName;
    }


}
