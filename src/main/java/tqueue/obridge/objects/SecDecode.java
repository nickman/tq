package tqueue.obridge.objects;

import java.sql.Timestamp;
import java.sql.Date;
import java.util.List;
import java.math.BigDecimal;
import javax.annotation.Generated;

@Generated("org.obridge.generators.EntityObjectGenerator")
public class SecDecode {

    private String securityDisplayName;
    private String securityType;
    private BigDecimal securityId;

    public String getSecurityDisplayName() {
        return this.securityDisplayName;
    }

    public void setSecurityDisplayName(String securityDisplayName) {
        this.securityDisplayName = securityDisplayName;
    }

    public String getSecurityType() {
        return this.securityType;
    }

    public void setSecurityType(String securityType) {
        this.securityType = securityType;
    }

    public BigDecimal getSecurityId() {
        return this.securityId;
    }

    public void setSecurityId(BigDecimal securityId) {
        this.securityId = securityId;
    }


}
