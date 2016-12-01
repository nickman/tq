package tqueue.obridge.context;

import java.sql.Timestamp;
import java.sql.Date;
import java.util.List;
import java.math.BigDecimal;
import java.sql.ResultSet;
import tqueue.obridge.objects.*;
import javax.annotation.Generated;

@Generated("org.obridge.generators.ProcedureContextGenerator")
public class TqDecodeSecurity2 {

    private String securitydisplayname;
    private BigDecimal securityid;
    private String securitytype;

    public String getSecuritydisplayname() {
        return this.securitydisplayname;
    }

    public void setSecuritydisplayname(String securitydisplayname) {
        this.securitydisplayname = securitydisplayname;
    }

    public BigDecimal getSecurityid() {
        return this.securityid;
    }

    public void setSecurityid(BigDecimal securityid) {
        this.securityid = securityid;
    }

    public String getSecuritytype() {
        return this.securitytype;
    }

    public void setSecuritytype(String securitytype) {
        this.securitytype = securitytype;
    }


}
