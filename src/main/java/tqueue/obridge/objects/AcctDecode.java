package tqueue.obridge.objects;

import java.sql.Timestamp;
import java.sql.Date;
import java.util.List;
import java.math.BigDecimal;
import javax.annotation.Generated;

@Generated("org.obridge.generators.EntityObjectGenerator")
public class AcctDecode {

    private String accountDisplayName;
    private BigDecimal accountId;

    public String getAccountDisplayName() {
        return this.accountDisplayName;
    }

    public void setAccountDisplayName(String accountDisplayName) {
        this.accountDisplayName = accountDisplayName;
    }

    public BigDecimal getAccountId() {
        return this.accountId;
    }

    public void setAccountId(BigDecimal accountId) {
        this.accountId = accountId;
    }


}
